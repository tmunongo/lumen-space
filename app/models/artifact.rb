class Artifact < ApplicationRecord
  TYPES = %w[web_page raw_link note quote image markdown].freeze
  LINK_TYPES = %w[related supports contradicts background quotes depends_on].freeze

  belongs_to :project
  has_many :artifact_tags, dependent: :destroy
  has_many :highlights, class_name: "ArtifactHighlight", dependent: :destroy
  has_many :outgoing_links, class_name: "ArtifactLink", foreign_key: :source_artifact_id, dependent: :destroy
  has_many :incoming_links, class_name: "ArtifactLink", foreign_key: :target_artifact_id, dependent: :destroy

  validates :title, presence: true
  validates :artifact_type, inclusion: { in: TYPES }
  validates :attribution, presence: true, if: -> { artifact_type == "quote" }
  validates :source_url, presence: true, if: -> { %w[web_page raw_link].include?(artifact_type) }

  scope :by_project, ->(project_id) { where(project_id: project_id) }
  scope :by_type, ->(type) { where(artifact_type: type) }
  scope :fetched, -> { where(is_fetched: true) }
  scope :by_tag, ->(tag) { joins(:artifact_tags).where(artifact_tags: { name: tag.downcase.strip }) }
  scope :recent, -> { order(created_at: :desc) }

  def tag_names
    artifact_tags.pluck(:name)
  end

  def add_tag(name)
    normalized = name.strip.downcase
    return if normalized.blank? || normalized.length > 50
    artifact_tags.find_or_create_by!(name: normalized)
  end

  def remove_tag(name)
    artifact_tags.where(name: name.strip.downcase).destroy_all
  end

  def set_tags(names)
    normalized = names.map { |n| n.strip.downcase }.uniq.reject(&:blank?)
    artifact_tags.where.not(name: normalized).destroy_all
    normalized.each { |n| artifact_tags.find_or_create_by!(name: n) }
  end

  def web_type?
    %w[web_page raw_link].include?(artifact_type)
  end

  def reading_time_minutes
    return 0 unless content.present?
    text = ActionController::Base.helpers.strip_tags(content)
    words = text.split.size
    [ (words / 200.0).ceil, 1 ].max
  end

  def type_icon
    {
      "web_page"  => "🌐",
      "raw_link"  => "🔗",
      "note"      => "📝",
      "quote"     => "💬",
      "image"     => "🖼️",
      "markdown"  => "📄"
    }[artifact_type] || "📁"
  end

  def type_label
    artifact_type.humanize
  end
end
