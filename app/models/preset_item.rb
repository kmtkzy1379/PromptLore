class PresetItem < ApplicationRecord
  belongs_to :preset

  has_one_attached :file

  enum :file_type, { claude_md: 0, skill: 1 }

  validates :file_type, presence: true
  validate :file_must_be_attached, on: :create
  validate :file_must_be_markdown
  validate :file_size_within_limit

  private

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def file_must_be_markdown
    return unless file.attached?
    errors.add(:file, "must be a .md file") unless file.filename.to_s.downcase.end_with?(".md")
  end

  def file_size_within_limit
    return unless file.attached?
    errors.add(:file, "must be less than 2MB") if file.byte_size > 2.megabytes
  end
end
