# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160513060333) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "article_categorisations", force: :cascade do |t|
    t.integer  "article_id"
    t.integer  "category_id"
    t.integer  "position"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "articles", force: :cascade do |t|
    t.string   "title",                  limit: 255
    t.text     "teaser"
    t.string   "author",                 limit: 255
    t.datetime "publication"
    t.text     "body"
    t.integer  "issue_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "trialarticle"
    t.boolean  "keynote"
    t.text     "source"
    t.string   "featured_image",         limit: 255
    t.text     "featured_image_caption"
    t.boolean  "hide_author_name"
    t.integer  "story_id"
    t.datetime "notification_sent"
    t.boolean  "unpublished"
  end

  add_index "articles", ["issue_id"], name: "index_articles_on_issue_id", using: :btree

  create_table "categories", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "display_name", limit: 255
    t.integer  "colour"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "favourites", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "article_id"
    t.integer  "issue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "guest_passes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "article_id"
    t.string   "key",        limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.datetime "last_used"
    t.integer  "use_count",              default: 0
  end

  add_index "guest_passes", ["article_id"], name: "index_guest_passes_on_article_id", using: :btree
  add_index "guest_passes", ["user_id"], name: "index_guest_passes_on_user_id", using: :btree

  create_table "images", force: :cascade do |t|
    t.string   "data",       limit: 255
    t.integer  "article_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "media_id"
    t.integer  "height"
    t.integer  "width"
    t.integer  "position"
    t.string   "credit",     limit: 255
    t.text     "caption"
    t.boolean  "hidden"
  end

  add_index "images", ["article_id"], name: "index_images_on_article_id", using: :btree

  create_table "issues", force: :cascade do |t|
    t.string   "title",             limit: 255
    t.integer  "number"
    t.datetime "release"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.boolean  "trialissue"
    t.string   "cover",             limit: 255
    t.text     "editors_letter"
    t.string   "editors_name",      limit: 255
    t.string   "editors_photo",     limit: 255
    t.boolean  "published"
    t.text     "email_text"
    t.string   "zip",               limit: 255
    t.datetime "notification_sent"
    t.boolean  "digital_exclusive"
  end

  create_table "pages", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "permalink",  limit: 255
    t.text     "body"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.text     "teaser"
  end

  add_index "pages", ["permalink"], name: "index_pages_on_permalink", using: :btree

  create_table "payment_notifications", force: :cascade do |t|
    t.string   "status",           limit: 255
    t.string   "transaction_id",   limit: 255
    t.string   "transaction_type", limit: 255
    t.integer  "user_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "purchases", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "issue_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "price_paid"
    t.datetime "purchase_date"
    t.string   "paypal_payer_id",   limit: 255
    t.string   "paypal_first_name", limit: 255
    t.string   "paypal_last_name",  limit: 255
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255, null: false
    t.text     "data"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string   "var",        limit: 255, null: false
    t.text     "value"
    t.integer  "thing_id"
    t.string   "thing_type"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "settings", ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true, using: :btree

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.string   "paypal_payer_id",          limit: 255
    t.string   "paypal_profile_id",        limit: 255
    t.string   "paypal_first_name",        limit: 255
    t.string   "paypal_last_name",         limit: 255
    t.integer  "refund"
    t.string   "paypal_email",             limit: 255
    t.integer  "price_paid"
    t.datetime "purchase_date"
    t.datetime "cancellation_date"
    t.datetime "valid_from"
    t.integer  "duration"
    t.datetime "refunded_on"
    t.string   "paypal_street1",           limit: 255
    t.string   "paypal_street2",           limit: 255
    t.string   "paypal_city_name",         limit: 255
    t.string   "paypal_state_or_province", limit: 255
    t.string   "paypal_country_name",      limit: 255
    t.string   "paypal_postal_code",       limit: 255
    t.boolean  "paper_copy"
    t.string   "paypal_country_code",      limit: 255
  end

  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "username",               limit: 255
    t.boolean  "admin"
    t.boolean  "institution"
    t.integer  "parent_id"
    t.string   "ip_whitelist",           limit: 255
    t.string   "uk_id",                  limit: 255
    t.datetime "uk_expiry"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
