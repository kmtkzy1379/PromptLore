class PresetsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show, :download, :download_item ]
  before_action :set_preset, only: [ :show, :edit, :update, :destroy, :download, :download_item, :toggle_like ]
  before_action :check_visibility!, only: [ :show, :download, :download_item, :toggle_like ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy ]

  def index
    presets = Preset.public_preset.includes(:user, :categories, :tags)
    presets = apply_filters(presets)
    presets = apply_sort(presets)
    @pagy, @presets = pagy(presets, items: 20)
  end

  def show
  end

  def new
    @preset = Preset.new
    @preset.preset_items.build
    @categories = Category.all
    @user_repositories = current_user.repositories.order(:name)
  end

  def create
    @preset = current_user.presets.build(preset_params)
    strip_official_unless_admin
    detect_file_types

    if @preset.save
      attach_repositories
      update_tags
      redirect_to @preset, notice: "Preset was successfully created."
    else
      @categories = Category.all
      @user_repositories = current_user.repositories.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.all
    @user_repositories = current_user.repositories.order(:name)
  end

  def update
    @preset.assign_attributes(preset_params)
    strip_official_unless_admin
    detect_file_types

    if @preset.save
      attach_repositories
      update_tags
      redirect_to @preset, notice: "Preset was successfully updated."
    else
      @categories = Category.all
      @user_repositories = current_user.repositories.order(:name)
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
    files = @preset.all_files
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
      if pr.repository.file.attached?
        redirect_to rails_blob_path(pr.repository.file, disposition: "attachment")
      else
        redirect_to @preset, alert: "No file attached."
      end
    else
      redirect_to @preset, alert: "Invalid item type."
    end
  end

  def toggle_like
    like = @preset.preset_likes.find_by(user: current_user)

    if like
      like.destroy
    else
      @preset.preset_likes.create(user: current_user)
    end

    redirect_to @preset
  end

  private

  def set_preset
    @preset = Preset.find(params[:id])
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
      preset_items_attributes: [ :id, :file, :position, :_destroy ]
    )
  end

  def strip_official_unless_admin
    @preset.official = false unless current_user.admin?
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

  def apply_filters(scope)
    if params[:category_id].present?
      scope = scope.joins(:preset_categories).where(preset_categories: { category_id: params[:category_id] })
    end

    if params[:tag].present?
      sanitized_tag = Preset.sanitize_sql_like(params[:tag])
      scope = scope.joins(:tags).where("tags.name LIKE ?", "%#{sanitized_tag}%")
    end

    if params[:q].present?
      sanitized_q = Preset.sanitize_sql_like(params[:q])
      scope = scope.where("presets.name LIKE :q OR presets.description LIKE :q", q: "%#{sanitized_q}%")
    end

    if params[:official] == "true"
      scope = scope.where(official: true)
    end

    scope
  end

  def apply_sort(scope)
    case params[:sort]
    when "oldest"
      scope.order(created_at: :asc)
    when "popular"
      scope.order(likes_count: :desc)
    when "trending"
      scope.except(:includes)
           .left_joins(:preset_likes)
           .preload(:user, :categories, :tags)
           .where("preset_likes.created_at > ? OR preset_likes.created_at IS NULL", 1.week.ago)
           .group("presets.id")
           .order(Arel.sql("COUNT(preset_likes.id) DESC"))
    else
      scope.order(created_at: :desc)
    end
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
