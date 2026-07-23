class CreateArtifactTags < ActiveRecord::Migration[8.1]
  def change
    create_table :artifact_tags do |t|
      t.references :artifact, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :artifact_tags, [ :artifact_id, :name ], unique: true
    add_index :artifact_tags, :name
  end
end
