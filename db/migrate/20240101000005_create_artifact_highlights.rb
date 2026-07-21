class CreateArtifactHighlights < ActiveRecord::Migration[8.1]
  def change
    create_table :artifact_highlights do |t|
      t.references :artifact, null: false, foreign_key: true
      t.text :selected_text, null: false
      t.text :note
      t.string :style, null: false, default: 'yellow'
      t.timestamps
    end
  end
end
