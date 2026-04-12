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
  validate :avatar_content_type_valid
  validate :avatar_size_within_limit

  def admin?
    admin
  end

  private

  def avatar_content_type_valid
    return unless avatar.attached?
    unless avatar.content_type.in?(%w[image/png image/jpeg image/gif image/webp])
      errors.add(:avatar, "must be a PNG, JPEG, GIF, or WebP image")
    end
  end

  def avatar_size_within_limit
    return unless avatar.attached?
    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "must be less than 5MB")
    end
  end
end
