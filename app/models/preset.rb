class Preset < ApplicationRecord
  belongs_to :user

  has_many :preset_items, dependent: :destroy
  has_many :preset_repositories, dependent: :destroy
  has_many :repositories, through: :preset_repositories
  has_many :preset_categories, dependent: :destroy
  has_many :categories, through: :preset_categories
  has_many :preset_tags, dependent: :destroy
  has_many :tags, through: :preset_tags
  has_many :preset_likes, dependent: :destroy

  enum :visibility, { public_preset: 0, private_preset: 1 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :visibility, presence: true
  validate :official_only_by_admin

  accepts_nested_attributes_for :preset_items, allow_destroy: true, reject_if: :all_blank

  def liked_by?(user)
    return false unless user
    preset_likes.exists?(user: user)
  end

  def all_files
    files = []
    preset_items.order(:position).each do |item|
      files << { name: item.file.filename.to_s, blob: item.file } if item.file.attached?
    end
    preset_repositories.includes(repository: { file_attachment: :blob }).order(:position).each do |pr|
      files << { name: pr.repository.file.filename.to_s, blob: pr.repository.file } if pr.repository.file.attached?
    end
    files
  end

  private

  def official_only_by_admin
    if official_changed? && official? && !user&.admin?
      errors.add(:official, "can only be set by admin users")
    end
  end
end
