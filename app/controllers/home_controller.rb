class HomeController < ApplicationController
  def index
    repositories = Repository.public_repo.includes(:user, :categories, :tags)

    repositories = apply_filters(repositories)
    repositories = apply_sort(repositories)

    @pagy, @repositories = pagy(repositories, items: 20)
  end

  private

  def apply_filters(scope)
    if params[:category_id].present?
      scope = scope.joins(:repository_categories).where(repository_categories: { category_id: params[:category_id] })
    end

    if params[:tag].present?
      sanitized_tag = Repository.sanitize_sql_like(params[:tag])
      scope = scope.joins(:tags).where("tags.name LIKE ?", "%#{sanitized_tag}%")
    end

    if params[:q].present?
      sanitized_q = Repository.sanitize_sql_like(params[:q])
      scope = scope.where("repositories.name LIKE :q OR repositories.description LIKE :q", q: "%#{sanitized_q}%")
    end

    if params[:file_type].present?
      scope = scope.where(file_type: params[:file_type])
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
           .left_joins(:likes)
           .preload(:user, :categories, :tags)
           .where("likes.created_at > ? OR likes.created_at IS NULL", 1.week.ago)
           .group("repositories.id")
           .order(Arel.sql("COUNT(likes.id) DESC"))
    else
      scope.order(created_at: :desc)
    end
  end
end
