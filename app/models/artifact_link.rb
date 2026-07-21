class ArtifactLink < ApplicationRecord
  LINK_TYPES = %w[related supports contradicts background quotes depends_on].freeze

  belongs_to :project
  belongs_to :source_artifact, class_name: 'Artifact'
  belongs_to :target_artifact, class_name: 'Artifact'

  validates :link_type, inclusion: { in: LINK_TYPES }
  validates :source_artifact_id, uniqueness: { scope: :target_artifact_id, message: 'Link already exists' }
  validate :no_self_links

  def type_label
    link_type.humanize
  end

  private

  def no_self_links
    errors.add(:base, 'Cannot link an artifact to itself') if source_artifact_id == target_artifact_id
  end
end
