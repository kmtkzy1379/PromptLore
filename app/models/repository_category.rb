class RepositoryCategory < ApplicationRecord
  belongs_to :repository
  belongs_to :category
end
