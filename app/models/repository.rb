class Repository < ApplicationRecord
  belongs_to :user

  has_many :repository_categories, dependent: :destroy
  has_many :categories, through: :repository_categories
  has_many :repository_tags, dependent: :destroy
  has_many :tags, through: :repository_tags
  has_many :likes, dependent: :destroy
  has_many :preset_repositories, dependent: :destroy
  has_many :versions, class_name: "RepositoryVersion", dependent: :destroy

  has_one_attached :file

  enum :file_type, { claude_md: 0, skill: 1 }
  enum :visibility, { public_repo: 0, private_repo: 1 }

  validates :name, presence: true, length: { maximum: 100 }
  validates :file_type, presence: true
  validates :visibility, presence: true
  validate :file_must_be_attached, on: :create
  validate :file_must_be_markdown
  validate :file_size_within_limit
  validate :must_be_claude_md, on: :create
  validate :official_only_by_admin

  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end

  private

  def file_must_be_attached
    unless file.attached?
      errors.add(:file, "must be attached")
    end
  end

  def file_must_be_markdown
    return unless file.attached?
    unless file.filename.to_s.downcase.end_with?(".md")
      errors.add(:file, "must be a .md file")
    end
  end

  def file_size_within_limit
    return unless file.attached?
    if file.byte_size > 2.megabytes
      errors.add(:file, "must be less than 2MB")
    end
  end

  def official_only_by_admin
    if official_changed? && official? && !user&.admin?
      errors.add(:official, "can only be set by admin users")
    end
  end

  def must_be_claude_md
    return unless file.attached?
    unless file.filename.to_s.downcase == "claude.md"
      errors.add(:file, "must be named CLAUDE.md. Skills should be uploaded as a folder via Presets.")
    end
  end
end
