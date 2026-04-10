class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :repositories, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_repositories, through: :likes, source: :repository
  has_many :presets, dependent: :destroy
  has_many :preset_likes, dependent: :destroy
  has_many :liked_presets, through: :preset_likes, source: :preset

  has_one_attached :avatar

  validates :username, presence: true, uniqueness: true, length: { maximum: 30 }

  def admin?
    admin
  end
end
