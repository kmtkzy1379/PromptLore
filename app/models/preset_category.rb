class PresetCategory < ApplicationRecord
  belongs_to :preset
  belongs_to :category
end
