class PresetItem < ApplicationRecord
  belongs_to :preset

  has_one_attached :file

  enum :file_type, { claude_md: 0, skill: 1 }

  SKILL_BLOCKED_EXTENSIONS = %w[.exe .dll .so .dylib .bin .com .msi .dmg .iso .img .zip .tar .gz .rar .7z].freeze

  validates :file_type, presence: true
  validate :subdirectory_must_be_safe
  validate :file_must_be_attached, on: :create
  validate :file_must_be_valid_type
  validate :file_size_within_limit

  def skill_relative_path
    if subdirectory.present?
      "#{subdirectory}/#{file.filename}"
    else
      file.filename.to_s
    end
  end

  private

  def subdirectory_must_be_safe
    return if subdirectory.blank?
    if subdirectory.include?("..") || subdirectory.start_with?("/") || subdirectory.start_with?("\\")
      errors.add(:subdirectory, "contains invalid path")
    end
  end

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def file_must_be_valid_type
    return unless file.attached?

    filename = file.filename.to_s.downcase
    ext = File.extname(filename)

    if preset&.is_skill_package?
      if SKILL_BLOCKED_EXTENSIONS.include?(ext)
        errors.add(:file, "cannot upload binary/archive files (#{ext})")
      end
    else
      errors.add(:file, "must be a .md file") unless filename.end_with?(".md")
    end
  end

  def file_size_within_limit
    return unless file.attached?
    errors.add(:file, "must be less than 2MB") if file.byte_size > 2.megabytes
  end
end
