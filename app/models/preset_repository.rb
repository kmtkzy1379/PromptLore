class PresetRepository < ApplicationRecord
  belongs_to :preset
  belongs_to :repository

  validates :repository_id, uniqueness: { scope: :preset_id }
  validate :repository_must_belong_to_user

  private

  def repository_must_belong_to_user
    if preset&.user_id != repository&.user_id
      errors.add(:repository, "must belong to you")
    end
  end
end
