class Like < ApplicationRecord
  belongs_to :user
  belongs_to :repository, counter_cache: true

  validates :user_id, uniqueness: { scope: :repository_id }
end
