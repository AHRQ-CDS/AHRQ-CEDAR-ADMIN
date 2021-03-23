# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_18_182334) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "artifacts", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.text "description_html"
    t.text "description_markdown"
    t.bigint "repository_id", null: false
    t.string "url"
    t.string "doi"
    t.string "remote_identifier"
    t.string "cedar_identifier"
    t.string "artifact_type"
    t.string "artifact_status"
    t.date "published_on"
    t.jsonb "keywords", default: []
    t.jsonb "mesh_keywords", default: []
    t.text "keyword_text"
    t.text "mesh_keyword_text"
    t.tsvector "content_search"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index "to_tsvector('english'::regconfig, COALESCE(keyword_text, ''::text))", name: "index_artifacts_on_keyword_text", using: :gin
    t.index "to_tsvector('english'::regconfig, COALESCE(mesh_keyword_text, ''::text))", name: "index_artifacts_on_mesh_keyword_text", using: :gin
    t.index ["content_search"], name: "index_artifacts_on_content_search", using: :gin
    t.index ["keywords"], name: "index_artifacts_on_keywords", using: :gin
    t.index ["mesh_keywords"], name: "index_artifacts_on_mesh_keywords", using: :gin
    t.index ["repository_id"], name: "index_artifacts_on_repository_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.string "name"
    t.string "home_page"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "artifacts", "repositories"
end
