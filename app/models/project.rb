class Project < ApplicationRecord
  has_many :artifacts, dependent: :destroy
  has_many :artifact_links, dependent: :destroy

  validates :name, presence: true, length: { maximum: 200 }, uniqueness: { case_sensitive: false }

  scope :active, -> { where(is_archived: false) }
  scope :archived, -> { where(is_archived: true) }
  scope :by_name, -> { order(:name) }
  scope :by_modified, -> { order(updated_at: :desc) }
  scope :by_created, -> { order(created_at: :desc) }

  before_save { name.strip! }

  def archive!
    update!(is_archived: true)
  end

  def unarchive!
    update!(is_archived: false)
  end

  def artifact_count
    artifacts.count
  end
end
