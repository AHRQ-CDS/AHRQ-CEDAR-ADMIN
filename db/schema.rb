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

ActiveRecord::Schema.define(version: 2022_07_20_161824) do

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
    t.text "keyword_text"
    t.tsvector "content_search"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "strength_of_recommendation_statement"
    t.string "strength_of_recommendation_score"
    t.integer "strength_of_recommendation_sort", default: 0
    t.string "quality_of_evidence_statement"
    t.string "quality_of_evidence_score"
    t.integer "quality_of_evidence_sort", default: 0
    t.integer "published_on_precision"
    t.datetime "published_on_start"
    t.datetime "published_on_end"
    t.index "to_tsvector('english'::regconfig, COALESCE(keyword_text, ''::text))", name: "index_artifacts_on_keyword_text", using: :gin
    t.index ["content_search"], name: "index_artifacts_on_content_search", using: :gin
    t.index ["keywords"], name: "index_artifacts_on_keywords", using: :gin
    t.index ["repository_id"], name: "index_artifacts_on_repository_id"
  end

  create_table "artifacts_concepts", id: false, force: :cascade do |t|
    t.bigint "concept_id"
    t.bigint "artifact_id"
    t.index ["artifact_id"], name: "index_artifacts_concepts_on_artifact_id"
    t.index ["concept_id"], name: "index_artifacts_concepts_on_concept_id"
  end

  create_table "concepts", force: :cascade do |t|
    t.string "umls_cui"
    t.string "umls_description"
    t.jsonb "synonyms_text", default: []
    t.jsonb "synonyms_psql", default: []
    t.jsonb "codes", default: []
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["codes"], name: "index_concepts_on_codes", using: :gin
    t.index ["synonyms_psql"], name: "index_concepts_on_synonyms_psql", using: :gin
    t.index ["synonyms_text"], name: "index_concepts_on_synonyms_text", using: :gin
    t.index ["umls_cui"], name: "index_concepts_on_umls_cui", unique: true
  end

  create_table "import_runs", force: :cascade do |t|
    t.bigint "repository_id", null: false
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "status"
    t.string "error_message"
    t.integer "total_count", default: 0, null: false
    t.integer "new_count", default: 0, null: false
    t.integer "update_count", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "delete_count", default: 0, null: false
    t.jsonb "error_msgs", default: []
    t.jsonb "warning_msgs", default: []
    t.index ["repository_id"], name: "index_import_runs_on_repository_id"
  end

  create_table "mesh_tree_nodes", force: :cascade do |t|
    t.string "code"
    t.string "tree_number"
    t.string "name"
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "parent_id"
    t.integer "direct_artifact_count"
    t.integer "indirect_artifact_count"
    t.index ["code"], name: "index_mesh_tree_nodes_on_code"
    t.index ["parent_id"], name: "index_mesh_tree_nodes_on_parent_id"
    t.index ["tree_number"], name: "index_mesh_tree_nodes_on_tree_number"
  end

  create_table "repositories", force: :cascade do |t|
    t.string "alias"
    t.string "fhir_id"
    t.string "home_page"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.index ["fhir_id"], name: "index_artifacts_on_fhir_id"
  end

  create_table "search_logs", force: :cascade do |t|
    t.jsonb "search_params", default: {}
    t.integer "count"
    t.integer "total"
    t.cidr "client_ip"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "repository_results", default: {}
    t.jsonb "link_clicks", default: []
  end

  create_table "users", force: :cascade do |t|
    t.string "username", default: "", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.bigint "import_run_id", null: false
    t.datetime "created_at"
    t.index ["import_run_id"], name: "index_versions_on_import_run_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "artifacts", "repositories"
  add_foreign_key "import_runs", "repositories"
  add_foreign_key "versions", "import_runs"
end
