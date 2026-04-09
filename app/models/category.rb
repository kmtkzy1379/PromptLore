class Category < ApplicationRecord
  has_many :repository_categories, dependent: :destroy
  has_many :repositories, through: :repository_categories

  validates :name, presence: true, uniqueness: true
end
