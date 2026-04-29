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

ActiveRecord::Schema[8.0].define(version: 2026_04_29_093004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.bigint "user_id"
    t.string "kind", null: false
    t.string "currency", default: "USD", null: false
    t.bigint "balance_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "kind"], name: "index_accounts_on_user_id_and_kind"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "journal_entries", force: :cascade do |t|
    t.string "idempotency_key", null: false
    t.string "memo"
    t.bigint "reverses_journal_entry_id"
    t.string "source_type"
    t.bigint "source_id"
    t.datetime "posted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idempotency_key"], name: "index_journal_entries_on_idempotency_key", unique: true
    t.index ["reverses_journal_entry_id"], name: "index_journal_entries_on_reverses_journal_entry_id", unique: true
    t.index ["source_type", "source_id"], name: "index_journal_entries_on_source_type_and_source_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "amount_cents", null: false
    t.string "currency", default: "USD", null: false
    t.string "status", default: "created", null: false
    t.bigint "paid_journal_entry_id"
    t.bigint "cancellation_journal_entry_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cancellation_journal_entry_id"], name: "index_orders_on_cancellation_journal_entry_id"
    t.index ["paid_journal_entry_id"], name: "index_orders_on_paid_journal_entry_id"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "postings", force: :cascade do |t|
    t.bigint "journal_entry_id", null: false
    t.bigint "account_id", null: false
    t.string "direction", null: false
    t.bigint "amount_cents", null: false
    t.string "currency", null: false
    t.datetime "created_at", null: false
    t.index ["account_id", "created_at"], name: "index_postings_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_postings_on_account_id"
    t.index ["journal_entry_id"], name: "index_postings_on_journal_entry_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "journal_entries", "journal_entries", column: "reverses_journal_entry_id"
  add_foreign_key "orders", "journal_entries", column: "cancellation_journal_entry_id"
  add_foreign_key "orders", "journal_entries", column: "paid_journal_entry_id"
  add_foreign_key "orders", "users"
  add_foreign_key "postings", "accounts"
  add_foreign_key "postings", "journal_entries"
end
