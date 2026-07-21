class ArtifactTag < ApplicationRecord
  belongs_to :artifact

  validates :name, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { scope: :artifact_id }

  before_save { name.downcase!.strip! }
end
