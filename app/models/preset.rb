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
  has_many :versions, class_name: "PresetVersion", dependent: :destroy

  enum :visibility, { public_preset: 0, private_preset: 1 }
  enum :preset_type, { skill_only: 0, mixed: 1 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :visibility, presence: true
  validates :is_skill_package, inclusion: { in: [ true, false ] }
  validate :official_only_by_admin

  accepts_nested_attributes_for :preset_items, allow_destroy: true,
    reject_if: proc { |attrs| attrs["file"].blank? && attrs["id"].blank? }

  def liked_by?(user)
    return false unless user
    preset_likes.exists?(user: user)
  end

  def skill_name
    name.parameterize
  end

  def detect_skill_package!
    has_skill_md = preset_items.any? { |item|
      item.file.attached? &&
      item.file.filename.to_s.casecmp("skill.md").zero? &&
      item.subdirectory.blank?
    }
    self.is_skill_package = has_skill_md
  end

  def all_files(viewer: nil)
    files = []
    preset_items.order(:position).each do |item|
      next unless item.file.attached?
      zip_name = if is_skill_package? && item.subdirectory.present?
                   "#{item.subdirectory}/#{item.file.filename}"
                 else
                   item.file.filename.to_s
                 end
      files << { name: zip_name, blob: item.file }
    end
    preset_repositories.includes(repository: { file_attachment: :blob }).order(:position).each do |pr|
      next unless pr.repository.file.attached?
      next if pr.repository.private_repo? && pr.repository.user != viewer
      files << { name: pr.repository.file.filename.to_s, blob: pr.repository.file }
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
