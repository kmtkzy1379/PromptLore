class TagsController < ApplicationController
  def index
    if params[:q].present?
      sanitized = sanitize_sql_like(params[:q])
      tags = Tag.where("name LIKE ?", "%#{sanitized}%").limit(10)
    else
      tags = Tag.none
    end
    render json: tags.pluck(:name)
  end

  private

  def sanitize_sql_like(string)
    Tag.sanitize_sql_like(string)
  end
end
