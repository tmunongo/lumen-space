class ArtifactHighlight < ApplicationRecord
  STYLES = %w[yellow green blue pink red].freeze

  belongs_to :artifact

  validates :selected_text, presence: true
  validates :style, inclusion: { in: STYLES }

  def color_class
    "highlight--#{style}"
  end
end
