class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.boolean :is_archived, null: false, default: false
      t.timestamps
    end
    add_index :projects, :name, unique: true
    add_index :projects, :is_archived
  end
end
