class RepositoryVersion < ApplicationRecord
  belongs_to :repository
  has_one_attached :file

  validates :version_number, presence: true, uniqueness: { scope: :repository_id }

  scope :pinned, -> { where(pinned: true) }
  scope :unpinned, -> { where(pinned: false) }
end
