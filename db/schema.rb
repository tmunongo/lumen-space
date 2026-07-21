# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2024_01_01_000005) do
  create_table "artifact_highlights", force: :cascade do |t|
    t.integer "artifact_id", null: false
    t.datetime "created_at", null: false
    t.text "note"
    t.text "selected_text", null: false
    t.string "style", default: "yellow", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_id"], name: "index_artifact_highlights_on_artifact_id"
  end

  create_table "artifact_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "link_type", default: "related", null: false
    t.text "note"
    t.integer "project_id", null: false
    t.bigint "source_artifact_id", null: false
    t.bigint "target_artifact_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_artifact_links_on_project_id"
    t.index ["source_artifact_id", "target_artifact_id"], name: "idx_artifact_links_unique", unique: true
    t.index ["source_artifact_id"], name: "index_artifact_links_on_source_artifact_id"
    t.index ["target_artifact_id"], name: "index_artifact_links_on_target_artifact_id"
  end

  create_table "artifact_tags", force: :cascade do |t|
    t.integer "artifact_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_id", "name"], name: "index_artifact_tags_on_artifact_id_and_name", unique: true
    t.index ["artifact_id"], name: "index_artifact_tags_on_artifact_id"
    t.index ["name"], name: "index_artifact_tags_on_name"
  end

  create_table "artifacts", force: :cascade do |t|
    t.string "artifact_type", null: false
    t.string "attribution"
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "is_fetched", default: false, null: false
    t.string "local_asset_path"
    t.integer "project_id", null: false
    t.string "source_url"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["artifact_type"], name: "index_artifacts_on_artifact_type"
    t.index ["project_id"], name: "index_artifacts_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_archived", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["is_archived"], name: "index_projects_on_is_archived"
    t.index ["name"], name: "index_projects_on_name", unique: true
  end

  add_foreign_key "artifact_highlights", "artifacts"
  add_foreign_key "artifact_links", "artifacts", column: "source_artifact_id"
  add_foreign_key "artifact_links", "artifacts", column: "target_artifact_id"
  add_foreign_key "artifact_links", "projects"
  add_foreign_key "artifact_tags", "artifacts"
  add_foreign_key "artifacts", "projects"
end
