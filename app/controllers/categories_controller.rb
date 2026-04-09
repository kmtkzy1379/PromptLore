class CategoriesController < ApplicationController
  def index
    render json: Category.all.pluck(:id, :name).map { |id, name| { id: id, name: name } }
  end
end
