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

ActiveRecord::Schema[7.2].define(version: 2025_06_12_025738) do
  create_table "alto_boards", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "status_set_id"
    t.string "item_label_singular", default: "ticket"
    t.boolean "is_admin_only", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "single_view"
    t.index [ "name" ], name: "index_alto_boards_on_name"
    t.index [ "single_view" ], name: "index_alto_boards_on_single_view"
    t.index [ "slug" ], name: "index_alto_boards_on_slug", unique: true
    t.index [ "status_set_id" ], name: "index_alto_boards_on_status_set_id"
  end

  create_table "alto_comments", force: :cascade do |t|
    t.integer "ticket_id", null: false
    t.string "user_type"
    t.integer "user_id"
    t.integer "parent_id"
    t.text "content"
    t.integer "depth", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "content" ], name: "index_alto_comments_on_content"
    t.index [ "parent_id" ], name: "index_alto_comments_on_parent_id"
    t.index [ "ticket_id" ], name: "index_alto_comments_on_ticket_id"
    t.index [ "user_type", "user_id" ], name: "index_alto_comments_on_user"
  end

  create_table "alto_fields", force: :cascade do |t|
    t.integer "board_id", null: false
    t.string "label", null: false
    t.string "field_type", null: false
    t.text "field_options"
    t.integer "position", default: 0, null: false
    t.boolean "required", default: false, null: false
    t.string "placeholder"
    t.text "help_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "board_id", "position" ], name: "index_alto_fields_on_board_id_and_position"
    t.index [ "board_id" ], name: "index_alto_fields_on_board_id"
    t.index [ "field_type" ], name: "index_alto_fields_on_field_type"
  end

  create_table "alto_settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.string "value_type", default: "string"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "key" ], name: "index_alto_settings_on_key", unique: true
  end

  create_table "alto_status_sets", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "is_default" ], name: "index_alto_status_sets_on_is_default"
    t.index [ "name" ], name: "index_alto_status_sets_on_name"
  end

  create_table "alto_statuses", force: :cascade do |t|
    t.integer "status_set_id", null: false
    t.string "name", null: false
    t.string "color", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "slug" ], name: "index_alto_statuses_on_slug"
    t.index [ "status_set_id", "position" ], name: "index_alto_statuses_on_status_set_id_and_position"
    t.index [ "status_set_id", "slug" ], name: "index_alto_statuses_on_status_set_id_and_slug", unique: true
    t.index [ "status_set_id" ], name: "index_alto_statuses_on_status_set_id"
  end

  create_table "alto_subscriptions", force: :cascade do |t|
    t.string "email"
    t.integer "ticket_id"
    t.datetime "last_viewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "email" ], name: "index_alto_subscriptions_on_email"
    t.index [ "ticket_id", "email" ], name: "index_alto_subscriptions_on_ticket_id_and_email", unique: true
    t.index [ "ticket_id" ], name: "index_alto_subscriptions_on_ticket_id"
  end

  create_table "alto_tickets", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "status_slug"
    t.boolean "locked", default: false, null: false
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.integer "board_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "field_values"
    t.boolean "archived", default: false, null: false
    t.index [ "archived" ], name: "index_alto_tickets_on_archived"
    t.index [ "board_id" ], name: "index_alto_tickets_on_board_id"
    t.index [ "created_at" ], name: "index_alto_tickets_on_created_at"
    t.index [ "description" ], name: "index_alto_tickets_on_description"
    t.index [ "field_values" ], name: "index_alto_tickets_on_field_values"
    t.index [ "locked" ], name: "index_alto_tickets_on_locked"
    t.index [ "status_slug", "created_at" ], name: "index_alto_tickets_on_status_slug_and_created_at"
    t.index [ "status_slug" ], name: "index_alto_tickets_on_status_slug"
    t.index [ "title" ], name: "index_alto_tickets_on_title"
    t.index [ "user_type", "user_id" ], name: "index_alto_tickets_on_user"
  end

  create_table "alto_upvotes", force: :cascade do |t|
    t.string "upvotable_type", null: false
    t.integer "upvotable_id", null: false
    t.string "user_type", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "upvotable_type", "upvotable_id", "user_id" ], name: "index_upvotes_on_upvotable_and_user", unique: true
    t.index [ "upvotable_type", "upvotable_id" ], name: "index_alto_upvotes_on_upvotable"
    t.index [ "user_type", "user_id" ], name: "index_alto_upvotes_on_user"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "alto_boards", "alto_status_sets", column: "status_set_id"
  add_foreign_key "alto_comments", "alto_comments", column: "parent_id"
  add_foreign_key "alto_comments", "alto_tickets", column: "ticket_id"
  add_foreign_key "alto_fields", "alto_boards", column: "board_id"
  add_foreign_key "alto_statuses", "alto_status_sets", column: "status_set_id"
  add_foreign_key "alto_subscriptions", "alto_tickets", column: "ticket_id"
  add_foreign_key "alto_tickets", "alto_boards", column: "board_id"
end
