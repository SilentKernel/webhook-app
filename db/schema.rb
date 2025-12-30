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

ActiveRecord::Schema[8.1].define(version: 2025_12_30_162835) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "connections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "destination_id", null: false
    t.string "name"
    t.integer "priority", default: 0
    t.jsonb "rules", default: []
    t.bigint "source_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["destination_id"], name: "index_connections_on_destination_id"
    t.index ["source_id", "destination_id"], name: "index_connections_on_source_id_and_destination_id", unique: true
    t.index ["source_id"], name: "index_connections_on_source_id"
    t.index ["status"], name: "index_connections_on_status"
  end

  create_table "destinations", force: :cascade do |t|
    t.integer "auth_type", default: 0, null: false
    t.string "auth_value"
    t.datetime "created_at", null: false
    t.jsonb "headers", default: {}
    t.string "http_method", default: "POST"
    t.integer "max_delivery_rate"
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "timeout_seconds", default: 30
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["organization_id"], name: "index_destinations_on_organization_id"
    t.index ["status"], name: "index_destinations_on_status"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.bigint "invited_by_id"
    t.bigint "organization_id", null: false
    t.integer "role", default: 0, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["organization_id", "email"], name: "index_invitations_on_organization_id_and_email", unique: true
    t.index ["organization_id"], name: "index_invitations_on_organization_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id", "organization_id"], name: "index_memberships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "source_types", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.jsonb "default_config", default: {}
    t.string "icon"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.string "verification_type", null: false
    t.index ["slug"], name: "index_source_types_on_slug", unique: true
  end

  create_table "sources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ingest_token", null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.bigint "source_type_id"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "verification_secret"
    t.string "verification_type", null: false
    t.index ["ingest_token"], name: "index_sources_on_ingest_token", unique: true
    t.index ["organization_id"], name: "index_sources_on_organization_id"
    t.index ["source_type_id"], name: "index_sources_on_source_type_id"
    t.index ["status"], name: "index_sources_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "connections", "destinations"
  add_foreign_key "connections", "sources"
  add_foreign_key "destinations", "organizations"
  add_foreign_key "invitations", "organizations"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "sources", "organizations"
  add_foreign_key "sources", "source_types"
end
