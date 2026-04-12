class PresetsController < ApplicationController
  include Filterable

  before_action :authenticate_user!, except: [ :index, :show, :download, :download_item, :raw_content ]
  before_action :set_preset, only: [ :edit, :update, :destroy, :download, :download_item, :raw_content, :toggle_like, :restore, :toggle_pin, :update_memo, :preview_version ]
  before_action :set_preset_with_includes, only: [ :show ]
  before_action :check_visibility!, only: [ :show, :download, :download_item, :raw_content, :toggle_like ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy, :restore, :toggle_pin, :update_memo, :preview_version ]

  def index
    presets = Preset.public_preset.includes(:user, :categories, :tags)
    presets = filter_scope(presets, :preset)
    presets = sort_scope(presets, :preset)
    @pagy, @presets = pagy(presets, items: 20)
  end

  def show
  end

  def new
    @preset = Preset.new
    @form_type = params[:type] == "preset" ? "preset" : "skill"
    @categories = Category.all
    @user_repositories = current_user.repositories.claude_md.order(:name)
  end

  def create
    @preset = current_user.presets.build(preset_params)
    @preset.preset_type = params[:type] == "preset" ? :mixed : :skill_only
    strip_official_unless_admin
    attach_uploaded_files
    detect_file_types

    save_succeeded = false
    ActiveRecord::Base.transaction do
      if @preset.save
        attach_repositories
        update_tags
        save_succeeded = true
      else
        raise ActiveRecord::Rollback
      end
    end

    if save_succeeded
      redirect_to @preset, notice: "Preset was successfully created."
    else
      @form_type = params[:type] == "preset" ? "preset" : "skill"
      @categories = Category.all
      @user_repositories = current_user.repositories.claude_md.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @form_type = @preset.preset_repositories.joins(:repository).where(repositories: { file_type: :claude_md }).exists? ? "preset" : "skill"
    @form_type = params[:type] if params[:type].present?
    @categories = Category.all
    @user_repositories = current_user.repositories.claude_md.order(:name)
  end

  def update
    update_succeeded = false
    ActiveRecord::Base.transaction do
      ::PresetVersionService.new.create_version!(@preset)
      @preset.assign_attributes(preset_params)
      strip_official_unless_admin
      attach_uploaded_files
      detect_file_types

      if @preset.save
        attach_repositories
        update_tags
        update_succeeded = true
      else
        raise ActiveRecord::Rollback
      end
    end

    if update_succeeded
      redirect_to @preset, notice: "Preset was successfully updated."
    else
      @form_type = params[:type] == "preset" ? "preset" : "skill"
      @categories = Category.all
      @user_repositories = current_user.repositories.claude_md.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if params[:password].blank?
      redirect_to @preset, alert: "Password is required to delete a preset."
      return
    end

    unless current_user.valid_password?(params[:password])
      redirect_to @preset, alert: "Incorrect password."
      return
    end

    @preset.destroy
    redirect_to root_path, notice: "Preset was successfully deleted."
  end

  def download
    files = @preset.all_files(viewer: current_user)
    if files.empty?
      redirect_to @preset, alert: "No files in this preset."
      return
    end

    @preset.increment!(:downloads_count)

    zip_data = generate_zip(files)
    send_data zip_data,
      type: "application/zip",
      filename: "#{@preset.name.parameterize}-preset.zip",
      disposition: "attachment"
  end

  def download_item
    if params[:item_type] == "preset_item"
      item = @preset.preset_items.find(params[:item_id])
      if item.file.attached?
        redirect_to rails_blob_path(item.file, disposition: "attachment")
      else
        redirect_to @preset, alert: "No file attached."
      end
    elsif params[:item_type] == "repository"
      pr = @preset.preset_repositories.find_by!(repository_id: params[:item_id])
      if pr.repository.private_repo? && pr.repository.user != current_user
        redirect_to @preset, alert: "Not authorized."
        return
      end
      if pr.repository.file.attached?
        redirect_to rails_blob_path(pr.repository.file, disposition: "attachment")
      else
        redirect_to @preset, alert: "No file attached."
      end
    else
      redirect_to @preset, alert: "Invalid item type."
    end
  end

  def raw_content
    files = []
    @preset.preset_items.order(:position).each do |item|
      next unless item.file.attached?
      files << {
        filename: item.file.filename.to_s,
        file_type: item.file_type,
        subdirectory: item.subdirectory,
        content_type: item.file.content_type,
        content: item.file.download.encode("UTF-8", "UTF-8", invalid: :replace, undef: :replace, replace: "?")
      }
    end
    @preset.preset_repositories.includes(repository: { file_attachment: :blob }).order(:position).each do |pr|
      next unless pr.repository.file.attached?
      next if pr.repository.private_repo? && pr.repository.user != current_user
      files << {
        filename: pr.repository.file.filename.to_s,
        file_type: pr.repository.file_type,
        subdirectory: "",
        content_type: pr.repository.file.content_type,
        content: pr.repository.file.download.encode("UTF-8", "UTF-8", invalid: :replace, undef: :replace, replace: "?")
      }
    end
    render json: {
      name: @preset.name,
      skill_name: @preset.skill_name,
      is_skill_package: @preset.is_skill_package,
      files: files
    }
  end

  def restore
    version = @preset.versions.find(params[:version_id])
    skipped = ::PresetVersionService.new.restore_version!(@preset, version)
    notice = "v#{version.version_number} に復元しました。"
    if skipped.any?
      notice += " （削除済みのリポジトリ #{skipped.size} 件はスキップされました）"
    end
    redirect_to @preset, notice: notice
  end

  def toggle_pin
    version = @preset.versions.find(params[:version_id])
    service = ::PresetVersionService.new
    if version.pinned?
      service.toggle_pin!(version)
      redirect_to @preset, notice: "ピン留めを解除しました。"
    else
      if service.toggle_pin!(version)
        redirect_to @preset, notice: "v#{version.version_number} をピン留めしました。"
      else
        redirect_to @preset, alert: "ピン留めは最大3件までです。既存のピンを外してください。"
      end
    end
  end

  def update_memo
    version = @preset.versions.find(params[:version_id])
    ::PresetVersionService.new.update_memo!(version, params[:memo].to_s.strip)
    redirect_to @preset, notice: "メモを更新しました。"
  end

  def preview_version
    @version = @preset.versions.includes(preset_version_items: { file_attachment: :blob }).find(params[:version_id])
    render partial: "presets/version_preview", locals: { version: @version }, layout: false
  end

  def toggle_like
    like = @preset.preset_likes.find_by(user: current_user)

    if like
      like.destroy
    else
      @preset.preset_likes.create!(user: current_user)
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    retry_like = @preset.preset_likes.find_by(user: current_user)
    retry_like&.destroy
  ensure
    redirect_to @preset
  end

  private

  def set_preset
    @preset = Preset.find(params[:id])
  end

  def set_preset_with_includes
    @preset = Preset.includes(
      preset_items: { file_attachment: :blob },
      preset_repositories: { repository: [ :user, { file_attachment: :blob } ] }
    ).find(params[:id])
  end

  def check_visibility!
    if @preset.private_preset? && @preset.user != current_user
      raise ActiveRecord::RecordNotFound
    end
  end

  def authorize_owner!
    redirect_to root_path, alert: "Not authorized." unless @preset.user == current_user
  end

  def preset_params
    params.require(:preset).permit(
      :name, :description, :visibility, :official,
      category_ids: [],
      preset_items_attributes: [ :id, :file, :position, :subdirectory, :_destroy ]
    )
  end

  def strip_official_unless_admin
    @preset.official = false unless current_user.admin?
  end

  def attach_uploaded_files
    # Handle folder upload (webkitdirectory)
    if params[:folder_files].present?
      paths = begin
        JSON.parse(params[:folder_paths].to_s)
      rescue JSON::ParserError
        []
      end

      params[:folder_files].each_with_index do |file, i|
        path_info = paths[i] || {}
        next if path_info["skip"]

        subdirectory = path_info["subdirectory"].to_s
        @preset.preset_items.build(
          file: file,
          subdirectory: subdirectory,
          position: @preset.preset_items.size,
          file_type: :skill
        )
      end
    end

    # Handle individual file upload
    if params[:upload_files].present?
      params[:upload_files].each do |file|
        @preset.preset_items.build(
          file: file,
          subdirectory: "",
          position: @preset.preset_items.size,
          file_type: :skill
        )
      end
    end
  end

  def detect_file_types
    @preset.preset_items.each do |item|
      next unless item.file.attached?
      if item.file.filename.to_s.downcase == "claude.md"
        item.file_type = :claude_md
      else
        item.file_type = :skill
      end
    end
    @preset.detect_skill_package!
  end

  def attach_repositories
    return unless params.key?(:repository_ids)
    @preset.preset_repositories.destroy_all
    repository_ids = Array(params[:repository_ids]).reject(&:blank?)
    repository_ids.each_with_index do |repo_id, index|
      @preset.preset_repositories.create(repository_id: repo_id, position: index)
    end
  end

  def update_tags
    return unless params.key?(:tag_names)
    tag_names = params[:tag_names].to_s.split(",").map(&:strip).reject(&:blank?)
    tags = tag_names.map { |name| Tag.find_or_create_by!(name: name) }
    @preset.tags = tags
  end

  def generate_zip(files)
    require "zip"
    buffer = Zip::OutputStream.write_buffer do |zip|
      seen_names = {}
      files.each do |f|
        name = f[:name]
        if seen_names[name]
          seen_names[name] += 1
          ext = File.extname(name)
          base = File.basename(name, ext)
          name = "#{base}_#{seen_names[name]}#{ext}"
        else
          seen_names[name] = 0
        end
        zip.put_next_entry(name)
        zip.write(f[:blob].download)
      end
    end
    buffer.string
  end
end
