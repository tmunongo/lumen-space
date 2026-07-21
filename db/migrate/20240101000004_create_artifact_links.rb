class CreateArtifactLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :artifact_links do |t|
      t.references :project, null: false, foreign_key: true
      t.bigint :source_artifact_id, null: false
      t.bigint :target_artifact_id, null: false
      t.string :link_type, null: false, default: 'related'
      t.text :note
      t.timestamps
    end
    add_index :artifact_links, [:source_artifact_id, :target_artifact_id], unique: true, name: 'idx_artifact_links_unique'
    add_index :artifact_links, :source_artifact_id
    add_index :artifact_links, :target_artifact_id
    add_foreign_key :artifact_links, :artifacts, column: :source_artifact_id
    add_foreign_key :artifact_links, :artifacts, column: :target_artifact_id
  end
end
