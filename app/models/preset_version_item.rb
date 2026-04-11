class PresetVersionItem < ApplicationRecord
  belongs_to :preset_version
  has_one_attached :file
end
