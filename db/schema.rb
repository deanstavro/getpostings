# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180708232758) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string   "name"
    t.string   "phone_number"
    t.string   "website"
    t.string   "industry"
    t.text     "description"
    t.text     "internal_notes"
    t.boolean  "do_not_contact",       default: false
    t.string   "number_of_employees"
    t.string   "address"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "zipcode"
    t.string   "timezone"
    t.string   "last_funding_type"
    t.string   "last_funding_amount"
    t.string   "total_funding_raised"
    t.string   "last_funding_date"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "status"
    t.integer  "client_company_id"
    t.index ["client_company_id"], name: "index_accounts_on_client_company_id", using: :btree
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.string   "author_type"
    t.integer  "author_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree
  end

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "client_companies", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.text     "company_notes"
    t.string   "company_domain"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.text     "airtable_keys"
    t.text     "replyio_keys"
    t.string   "api_key"
    t.integer  "number_of_seats"
    t.text     "emails_to_use"
    t.text     "products"
    t.text     "notable_clients"
    t.boolean  "profile_setup",   default: false
    t.boolean  "account_live",    default: false
    t.string   "account_manager"
  end

  create_table "demos", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "phone_number"
    t.string   "comments"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "find_companies", force: :cascade do |t|
    t.integer  "source"
    t.string   "url"
    t.string   "file_download"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "client_company_id"
    t.string   "keywords"
    t.string   "location"
    t.string   "status"
    t.index ["client_company_id"], name: "index_find_companies_on_client_company_id", using: :btree
  end

  create_table "find_contacts", force: :cascade do |t|
    t.string   "csv_file"
    t.string   "download_file"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "client_company_id"
    t.string   "seniority"
    t.string   "department"
    t.index ["client_company_id"], name: "index_find_contacts_on_client_company_id", using: :btree
  end

  create_table "leads", force: :cascade do |t|
    t.boolean  "decision_maker"
    t.text     "internal_notes"
    t.string   "email_in_contact_with"
    t.datetime "date_sourced"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "client_company_id"
    t.string   "contract_sent"
    t.integer  "contract_amount"
    t.string   "timeline"
    t.string   "project_scope"
    t.string   "email_handed_off_too"
    t.datetime "meeting_time"
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.integer  "hunter_score"
    t.datetime "hunter_date"
    t.string   "title"
    t.string   "phone_type"
    t.string   "phone_number"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.string   "linkedin"
    t.string   "timezone"
    t.string   "address"
    t.boolean  "meeting_taken",         default: false
    t.string   "full_name"
    t.integer  "status"
    t.string   "company_name"
    t.string   "company_website"
    t.integer  "account_id"
    t.index ["account_id"], name: "index_leads_on_account_id", using: :btree
    t.index ["client_company_id"], name: "index_leads_on_client_company_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role"
    t.integer  "client_company_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "api_key"
    t.index ["client_company_id"], name: "index_users_on_client_company_id", using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  add_foreign_key "accounts", "client_companies"
  add_foreign_key "find_companies", "client_companies"
  add_foreign_key "find_contacts", "client_companies"
  add_foreign_key "leads", "accounts"
  add_foreign_key "leads", "client_companies"
  add_foreign_key "users", "client_companies"
end
