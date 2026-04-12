class HomeController < ApplicationController
  include Filterable

  def index
    case params[:tab]
    when "skills"
      presets = Preset.skill_only.public_preset.includes(:user, :categories, :tags)
      presets = filter_scope(presets, :preset)
      presets = sort_scope(presets, :preset)
      @pagy, @skills = pagy(presets, items: 20)
    when "presets"
      presets = Preset.mixed.public_preset.includes(:user, :categories, :tags)
      presets = filter_scope(presets, :preset)
      presets = sort_scope(presets, :preset)
      @pagy, @presets = pagy(presets, items: 20)
    else
      repositories = Repository.public_repo.includes(:user, :categories, :tags)
      repositories = filter_scope(repositories, :repository)
      repositories = sort_scope(repositories, :repository)
      @pagy, @repositories = pagy(repositories, items: 20)
    end
  end
end
