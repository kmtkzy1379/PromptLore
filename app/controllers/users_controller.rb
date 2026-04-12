class UsersController < ApplicationController
  before_action :set_user
  before_action :authenticate_user!, only: [ :edit, :update ]
  before_action :authorize_user!, only: [ :edit, :update ]

  def show
    repositories = @user.repositories
    repositories = repositories.public_repo unless current_user == @user

    if params[:q].present?
      sanitized_q = Repository.sanitize_sql_like(params[:q])
      repositories = repositories.where("repositories.name LIKE :q OR repositories.description LIKE :q", q: "%#{sanitized_q}%")
    end

    if params[:file_type].present?
      repositories = repositories.where(file_type: params[:file_type])
    end

    if params[:tag].present?
      sanitized_tag = Repository.sanitize_sql_like(params[:tag])
      repositories = repositories.joins(:tags).where("tags.name LIKE ?", "%#{sanitized_tag}%")
    end

    case params[:sort]
    when "oldest"
      repositories = repositories.order(created_at: :asc)
    when "popular"
      repositories = repositories.order(likes_count: :desc)
    else
      repositories = repositories.order(created_at: :desc)
    end

    @pagy, @repositories = pagy(repositories.includes(:categories, :tags), items: 20, page_param: :repos_page)

    skills = @user.presets.skill_only
    skills = skills.public_preset unless current_user == @user
    @pagy_skills, @skills = pagy(skills.includes(:categories, :tags).order(created_at: :desc), items: 20, page_param: :skills_page)

    presets = @user.presets.mixed
    presets = presets.public_preset unless current_user == @user
    @pagy_presets, @presets = pagy(presets.includes(:categories, :tags).order(created_at: :desc), items: 20, page_param: :presets_page)
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_user!
    redirect_to root_path, alert: "Not authorized." unless @user == current_user
  end

  def user_params
    params.require(:user).permit(:username, :avatar)
  end
end
