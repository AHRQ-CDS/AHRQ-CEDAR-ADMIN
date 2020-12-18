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

ActiveRecord::Schema.define(version: 2020_12_18_183911) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "artifact_type_associations", force: :cascade do |t|
    t.bigint "artifact_id", null: false
    t.bigint "artifact_type_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["artifact_id"], name: "index_artifact_type_associations_on_artifact_id"
    t.index ["artifact_type_id"], name: "index_artifact_type_associations_on_artifact_type_id"
  end

  create_table "artifact_types", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "artifacts", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.bigint "repository_id", null: false
    t.string "url"
    t.date "published"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "remote_identifier"
    t.index ["repository_id"], name: "index_artifacts_on_repository_id"
  end

  create_table "repositories", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "artifact_type_associations", "artifact_types"
  add_foreign_key "artifact_type_associations", "artifacts"
  add_foreign_key "artifacts", "repositories"
end
