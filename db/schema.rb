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

ActiveRecord::Schema[8.1].define(version: 2026_05_19_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "article_categorisations", id: :serial, force: :cascade do |t|
    t.integer "article_id"
    t.integer "category_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "position"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "articles", id: :serial, force: :cascade do |t|
    t.string "author", limit: 255
    t.text "body"
    t.datetime "created_at", precision: nil, null: false
    t.string "featured_image", limit: 255
    t.text "featured_image_caption"
    t.boolean "hide_author_name"
    t.integer "issue_id"
    t.boolean "keynote"
    t.datetime "notification_sent", precision: nil
    t.datetime "publication", precision: nil
    t.text "source"
    t.integer "story_id"
    t.text "teaser"
    t.string "title", limit: 255
    t.boolean "trialarticle"
    t.boolean "unpublished"
    t.datetime "updated_at", precision: nil, null: false
    t.index ["issue_id"], name: "index_articles_on_issue_id"
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.integer "colour"
    t.datetime "created_at", precision: nil, null: false
    t.string "display_name", limit: 255
    t.string "name", limit: 255
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at", precision: nil
    t.string "locked_by"
    t.integer "priority", default: 0, null: false
    t.string "queue"
    t.datetime "run_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "favourites", id: :serial, force: :cascade do |t|
    t.integer "article_id"
    t.datetime "created_at", precision: nil, null: false
    t.integer "issue_id"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
  end

  create_table "guest_passes", id: :serial, force: :cascade do |t|
    t.integer "article_id"
    t.datetime "created_at", precision: nil, null: false
    t.string "key", limit: 255
    t.datetime "last_used", precision: nil
    t.datetime "updated_at", precision: nil, null: false
    t.integer "use_count", default: 0
    t.integer "user_id"
    t.index ["article_id"], name: "index_guest_passes_on_article_id"
    t.index ["user_id"], name: "index_guest_passes_on_user_id"
  end

  create_table "images", id: :serial, force: :cascade do |t|
    t.integer "article_id"
    t.text "caption"
    t.datetime "created_at", precision: nil, null: false
    t.string "credit", limit: 255
    t.string "data", limit: 255
    t.integer "height"
    t.boolean "hidden"
    t.integer "media_id"
    t.integer "position"
    t.datetime "updated_at", precision: nil, null: false
    t.integer "width"
    t.index ["article_id"], name: "index_images_on_article_id"
  end

  create_table "issues", id: :serial, force: :cascade do |t|
    t.string "cover", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.boolean "digital_exclusive"
    t.text "editors_letter"
    t.string "editors_name", limit: 255
    t.string "editors_photo", limit: 255
    t.text "email_text"
    t.datetime "notification_sent", precision: nil
    t.integer "number"
    t.boolean "published"
    t.datetime "release", precision: nil
    t.string "title", limit: 255
    t.boolean "trialissue"
    t.datetime "updated_at", precision: nil, null: false
    t.string "zip", limit: 255
  end

  create_table "pages", id: :serial, force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", precision: nil, null: false
    t.string "permalink", limit: 255
    t.text "teaser"
    t.string "title", limit: 255
    t.datetime "updated_at", precision: nil, null: false
    t.index ["permalink"], name: "index_pages_on_permalink"
  end

  create_table "payment_notifications", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "status", limit: 255
    t.string "transaction_id", limit: 255
    t.string "transaction_type", limit: 255
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
  end

  create_table "purchases", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "issue_id"
    t.string "paypal_first_name", limit: 255
    t.string "paypal_last_name", limit: 255
    t.string "paypal_payer_id", limit: 255
    t.integer "price_paid"
    t.datetime "purchase_date", precision: nil
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
  end

  create_table "push_registrations", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "device"
    t.text "token"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "rpush_apps", id: :serial, force: :cascade do |t|
    t.string "access_token"
    t.datetime "access_token_expiration", precision: nil
    t.text "apn_key"
    t.string "apn_key_id"
    t.string "auth_key"
    t.string "bundle_id"
    t.text "certificate"
    t.string "client_id"
    t.string "client_secret"
    t.integer "connections", default: 1, null: false
    t.datetime "created_at", precision: nil
    t.string "environment"
    t.boolean "feedback_enabled", default: true
    t.string "firebase_project_id"
    t.text "json_key"
    t.string "name", null: false
    t.string "password"
    t.string "team_id"
    t.string "type", null: false
    t.datetime "updated_at", precision: nil
  end

  create_table "rpush_feedback", id: :serial, force: :cascade do |t|
    t.integer "app_id"
    t.datetime "created_at", precision: nil
    t.string "device_token"
    t.datetime "failed_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil
    t.index ["device_token"], name: "index_rpush_feedback_on_device_token"
  end

  create_table "rpush_notifications", id: :serial, force: :cascade do |t|
    t.text "alert"
    t.boolean "alert_is_json", default: false, null: false
    t.integer "app_id", null: false
    t.integer "badge"
    t.string "category"
    t.string "collapse_key"
    t.boolean "content_available", default: false, null: false
    t.datetime "created_at", precision: nil
    t.text "data"
    t.boolean "delay_while_idle", default: false, null: false
    t.datetime "deliver_after", precision: nil
    t.boolean "delivered", default: false, null: false
    t.datetime "delivered_at", precision: nil
    t.string "device_token"
    t.boolean "dry_run", default: false, null: false
    t.integer "error_code"
    t.text "error_description"
    t.integer "expiry", default: 86400
    t.string "external_device_id"
    t.datetime "fail_after", precision: nil
    t.boolean "failed", default: false, null: false
    t.datetime "failed_at", precision: nil
    t.boolean "mutable_content", default: false, null: false
    t.text "notification"
    t.integer "priority"
    t.boolean "processing", default: false, null: false
    t.text "registration_ids"
    t.integer "retries", default: 0
    t.string "sound"
    t.boolean "sound_is_json", default: false
    t.string "thread_id"
    t.string "type", null: false
    t.datetime "updated_at", precision: nil
    t.string "uri"
    t.text "url_args"
    t.index ["delivered", "failed", "processing", "deliver_after", "created_at"], name: "index_rpush_notifications_multi", where: "((NOT delivered) AND (NOT failed))"
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.text "data"
    t.string "session_id", limit: 255, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.integer "thing_id"
    t.string "thing_type"
    t.datetime "updated_at", precision: nil, null: false
    t.text "value"
    t.string "var", limit: 255, null: false
    t.index ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.datetime "cancellation_date", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.integer "duration"
    t.boolean "paper_copy"
    t.boolean "paper_only"
    t.string "paypal_city_name", limit: 255
    t.string "paypal_country_code", limit: 255
    t.string "paypal_country_name", limit: 255
    t.string "paypal_email", limit: 255
    t.string "paypal_first_name", limit: 255
    t.string "paypal_last_name", limit: 255
    t.string "paypal_payer_id", limit: 255
    t.string "paypal_postal_code", limit: 255
    t.string "paypal_profile_id", limit: 255
    t.string "paypal_state_or_province", limit: 255
    t.string "paypal_street1", limit: 255
    t.string "paypal_street2", limit: 255
    t.integer "price_paid"
    t.datetime "purchase_date", precision: nil
    t.integer "refund"
    t.datetime "refunded_on", precision: nil
    t.datetime "updated_at", precision: nil, null: false
    t.integer "user_id"
    t.datetime "valid_from", precision: nil
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "address"
    t.boolean "admin"
    t.string "annuals_buyer"
    t.string "city"
    t.text "comments"
    t.string "company_name"
    t.string "country"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip", limit: 255
    t.string "digital_renewals"
    t.string "email", limit: 255, default: "", null: false
    t.string "email_opt_in"
    t.datetime "email_opt_in_updated", precision: nil
    t.datetime "email_updated", precision: nil
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "first_name"
    t.boolean "institution"
    t.string "ip_whitelist", limit: 255
    t.string "last_name"
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip", limit: 255
    t.boolean "manager"
    t.datetime "most_recent_products_order", precision: nil
    t.datetime "most_recent_subscriptions_order", precision: nil
    t.string "paper_renewals"
    t.integer "parent_id"
    t.string "phone"
    t.datetime "postal_address_updated", precision: nil
    t.string "postal_code"
    t.string "postal_mailable"
    t.datetime "postal_mailable_updated", precision: nil
    t.decimal "products_order_total"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token", limit: 255
    t.integer "sign_in_count", default: 0
    t.string "state"
    t.decimal "subscriptions_order_total"
    t.string "title"
    t.datetime "uk_expiry", precision: nil
    t.string "uk_id", limit: 255
    t.datetime "updated_at", precision: nil, null: false
    t.string "username", limit: 255
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end
end
