module Filterable
  extend ActiveSupport::Concern

  private

  def filter_scope(scope, resource_type)
    config = filter_config_for(resource_type)

    if params[:category_id].present?
      scope = scope.joins(config[:category_join])
                   .where(config[:category_table] => { category_id: params[:category_id] })
    end

    if params[:tag].present?
      sanitized = scope.model.sanitize_sql_like(params[:tag])
      scope = scope.joins(:tags).where("tags.name LIKE ?", "%#{sanitized}%")
    end

    if params[:q].present?
      sanitized = scope.model.sanitize_sql_like(params[:q])
      scope = scope.where(
        "#{config[:table]}.name LIKE :q OR #{config[:table]}.description LIKE :q",
        q: "%#{sanitized}%"
      )
    end

    if resource_type == :repository && params[:file_type].present?
      scope = scope.where(file_type: params[:file_type])
    end

    if resource_type == :preset && params[:official] == "true"
      scope = scope.where(official: true)
    end

    scope
  end

  def sort_scope(scope, resource_type)
    config = filter_config_for(resource_type)
    case params[:sort]
    when "oldest"
      scope.order(created_at: :asc)
    when "popular"
      scope.order(likes_count: :desc)
    when "trending"
      scope.except(:includes)
           .left_joins(config[:likes_assoc])
           .preload(:user, :categories, :tags)
           .where("#{config[:likes_table]}.created_at > ? OR #{config[:likes_table]}.created_at IS NULL", 1.week.ago)
           .group("#{config[:table]}.id")
           .order(Arel.sql("COUNT(#{config[:likes_table]}.id) DESC"))
    else
      scope.order(created_at: :desc)
    end
  end

  def filter_config_for(type)
    case type
    when :repository
      { table: "repositories", category_join: :repository_categories,
        category_table: :repository_categories, likes_assoc: :likes, likes_table: "likes" }
    when :preset
      { table: "presets", category_join: :preset_categories,
        category_table: :preset_categories, likes_assoc: :preset_likes, likes_table: "preset_likes" }
    end
  end
end
