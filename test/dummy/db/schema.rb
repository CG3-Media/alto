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

ActiveRecord::Schema[7.2].define(version: 2025_06_09_055254) do
  create_table "feedback_board_boards", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status_set_id"
    t.index ["name"], name: "index_feedback_board_boards_on_name"
    t.index ["slug"], name: "index_feedback_board_boards_on_slug", unique: true
    t.index ["status_set_id"], name: "index_feedback_board_boards_on_status_set_id"
  end

  create_table "feedback_board_comments", force: :cascade do |t|
    t.integer "ticket_id", null: false
    t.integer "user_id"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.integer "depth", default: 0, null: false
    t.index ["content"], name: "index_feedback_board_comments_on_content"
    t.index ["parent_id"], name: "index_feedback_board_comments_on_parent_id"
    t.index ["ticket_id"], name: "index_feedback_board_comments_on_ticket_id"
    t.index ["user_id"], name: "index_feedback_board_comments_on_user_id"
  end

  create_table "feedback_board_settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.string "value_type", default: "string"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_feedback_board_settings_on_key", unique: true
  end

  create_table "feedback_board_status_sets", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_default"], name: "index_feedback_board_status_sets_on_is_default"
    t.index ["name"], name: "index_feedback_board_status_sets_on_name"
  end

  create_table "feedback_board_statuses", force: :cascade do |t|
    t.integer "status_set_id", null: false
    t.string "name", null: false
    t.string "color", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_feedback_board_statuses_on_slug"
    t.index ["status_set_id", "position"], name: "index_feedback_board_statuses_on_status_set_id_and_position"
    t.index ["status_set_id", "slug"], name: "index_feedback_board_statuses_on_status_set_id_and_slug", unique: true
    t.index ["status_set_id"], name: "index_feedback_board_statuses_on_status_set_id"
  end

  create_table "feedback_board_tickets", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "status_slug", default: "open", null: false
    t.boolean "locked", default: false, null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "board_id", null: false
    t.index ["board_id"], name: "index_feedback_board_tickets_on_board_id"
    t.index ["created_at"], name: "index_feedback_board_tickets_on_created_at"
    t.index ["description"], name: "index_feedback_board_tickets_on_description"
    t.index ["locked"], name: "index_feedback_board_tickets_on_locked"
    t.index ["status_slug", "created_at"], name: "index_feedback_board_tickets_on_status_slug_and_created_at"
    t.index ["status_slug"], name: "index_feedback_board_tickets_on_status_slug"
    t.index ["title"], name: "index_feedback_board_tickets_on_title"
    t.index ["user_id"], name: "index_feedback_board_tickets_on_user_id"
  end

  create_table "feedback_board_upvotes", force: :cascade do |t|
    t.string "upvotable_type", null: false
    t.integer "upvotable_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["upvotable_type", "upvotable_id", "user_id"], name: "index_upvotes_on_upvotable_and_user", unique: true
    t.index ["upvotable_type", "upvotable_id"], name: "index_feedback_board_upvotes_on_upvotable"
    t.index ["user_id"], name: "index_feedback_board_upvotes_on_user_id"
  end

  add_foreign_key "feedback_board_boards", "feedback_board_status_sets", column: "status_set_id"
  add_foreign_key "feedback_board_comments", "feedback_board_comments", column: "parent_id"
  add_foreign_key "feedback_board_comments", "feedback_board_tickets", column: "ticket_id"
  add_foreign_key "feedback_board_statuses", "feedback_board_status_sets", column: "status_set_id"
  add_foreign_key "feedback_board_tickets", "feedback_board_boards", column: "board_id"
end
