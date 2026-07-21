class CreateArtifacts < ActiveRecord::Migration[8.1]
  def change
    create_table :artifacts do |t|
      t.references :project, null: false, foreign_key: true
      t.string :artifact_type, null: false
      t.string :title, null: false
      t.text :content
      t.string :source_url
      t.string :attribution
      t.string :local_asset_path
      t.boolean :is_fetched, null: false, default: false
      t.timestamps
    end
    add_index :artifacts, :artifact_type
  end
end
