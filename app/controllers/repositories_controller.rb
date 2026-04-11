class RepositoriesController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show, :download, :raw_content ]
  before_action :set_repository, only: [ :show, :edit, :update, :destroy, :download, :raw_content, :toggle_like ]
  before_action :check_visibility!, only: [ :show, :download, :raw_content, :toggle_like ]
  before_action :authorize_owner!, only: [ :edit, :update, :destroy ]

  def index
    repositories = Repository.public_repo.includes(:user, :categories, :tags).order(created_at: :desc)
    @pagy, @repositories = pagy(repositories, items: 20)
  end

  def show
  end

  def new
    @repository = Repository.new
    @categories = Category.all
  end

  def create
    @repository = current_user.repositories.build(repository_params)
    detect_file_type if @repository.file.attached?
    set_default_name if @repository.name.blank? && @repository.file.attached?

    if @repository.save
      update_tags
      redirect_to @repository, notice: "Repository was successfully created."
    else
      @categories = Category.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.all
  end

  def update
    @repository.assign_attributes(repository_params)
    detect_file_type if @repository.file.attached?

    if @repository.save
      update_tags
      redirect_to @repository, notice: "Repository was successfully updated."
    else
      @categories = Category.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if params[:password].blank?
      redirect_to @repository, alert: "Password is required to delete a repository."
      return
    end

    unless current_user.valid_password?(params[:password])
      redirect_to @repository, alert: "Incorrect password."
      return
    end

    @repository.destroy
    redirect_to root_path, notice: "Repository was successfully deleted."
  end

  def download
    if @repository.file.attached?
      @repository.increment!(:downloads_count)
      redirect_to rails_blob_path(@repository.file, disposition: "attachment")
    else
      redirect_to @repository, alert: "No file attached."
    end
  end

  def raw_content
    if @repository.file.attached?
      content = @repository.file.download.encode("UTF-8", "UTF-8", invalid: :replace, undef: :replace, replace: "?")
      render json: {
        filename: @repository.file.filename.to_s,
        file_type: @repository.file_type,
        name: @repository.name,
        content: content
      }
    else
      render json: { error: "No file attached" }, status: :not_found
    end
  end

  def toggle_like
    like = @repository.likes.find_by(user: current_user)

    if like
      like.destroy
    else
      @repository.likes.create(user: current_user)
    end

    redirect_to @repository
  end

  private

  def set_repository
    @repository = Repository.find(params[:id])
  end

  def check_visibility!
    if @repository.private_repo? && @repository.user != current_user
      raise ActiveRecord::RecordNotFound
    end
  end

  def authorize_owner!
    redirect_to root_path, alert: "Not authorized." unless @repository.user == current_user
  end

  def repository_params
    params.require(:repository).permit(:name, :description, :visibility, :file, category_ids: [])
  end

  def detect_file_type
    filename = @repository.file.filename.to_s
    if filename.downcase == "claude.md"
      @repository.file_type = :claude_md
    else
      @repository.file_type = :skill
    end
  end

  def set_default_name
    @repository.name = @repository.file.filename.to_s.sub(/\.md\z/i, "")
  end

  def update_tags
    return unless params.key?(:tag_names)
    tag_names = params[:tag_names].to_s.split(",").map(&:strip).reject(&:blank?)
    tags = tag_names.map { |name| Tag.find_or_create_by!(name: name) }
    @repository.tags = tags
  end
end
