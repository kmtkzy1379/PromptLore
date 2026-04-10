class PresetLike < ApplicationRecord
  belongs_to :user
  belongs_to :preset, counter_cache: :likes_count

  validates :user_id, uniqueness: { scope: :preset_id }
end
