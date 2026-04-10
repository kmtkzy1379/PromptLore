class Tag < ApplicationRecord
  has_many :repository_tags, dependent: :destroy
  has_many :repositories, through: :repository_tags
  has_many :preset_tags, dependent: :destroy
  has_many :presets, through: :preset_tags

  validates :name, presence: true, uniqueness: true
end
