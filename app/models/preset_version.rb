class PresetVersion < ApplicationRecord
  belongs_to :preset
  has_many :preset_version_items, dependent: :destroy
  has_one_attached :file

  validates :version_number, presence: true, uniqueness: { scope: :preset_id }
  validates :memo, length: { maximum: 500 }, allow_nil: true

  scope :pinned, -> { where(pinned: true) }
  scope :unpinned, -> { where(pinned: false) }
end
