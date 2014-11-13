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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20141112222537) do

  create_table "article_categorisations", :force => true do |t|
    t.integer  "article_id"
    t.integer  "category_id"
    t.integer  "position"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "articles", :force => true do |t|
    t.string   "title"
    t.text     "teaser"
    t.string   "author"
    t.datetime "publication"
    t.text     "body"
    t.integer  "issue_id"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.boolean  "trialarticle"
    t.boolean  "keynote"
    t.text     "source"
    t.string   "featured_image"
    t.text     "featured_image_caption"
    t.boolean  "hide_author_name"
    t.integer  "story_id"
    t.datetime "notification_sent"
  end

  add_index "articles", ["issue_id"], :name => "index_articles_on_issue_id"

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "display_name"
    t.integer  "colour"
  end

  create_table "favourites", :force => true do |t|
    t.integer  "user_id"
    t.integer  "article_id"
    t.integer  "issue_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "guest_passes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "article_id"
    t.string   "key"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.datetime "last_used"
    t.integer  "use_count",  :default => 0
  end

  add_index "guest_passes", ["article_id"], :name => "index_guest_passes_on_article_id"
  add_index "guest_passes", ["user_id"], :name => "index_guest_passes_on_user_id"

  create_table "images", :force => true do |t|
    t.string   "data"
    t.integer  "article_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "media_id"
    t.integer  "height"
    t.integer  "width"
    t.integer  "position"
    t.string   "credit"
    t.text     "caption"
    t.boolean  "hidden"
  end

  add_index "images", ["article_id"], :name => "index_images_on_article_id"

  create_table "issues", :force => true do |t|
    t.string   "title"
    t.integer  "number"
    t.datetime "release"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.boolean  "trialissue"
    t.string   "cover"
    t.text     "editors_letter"
    t.string   "editors_name"
    t.string   "editors_photo"
    t.boolean  "published"
    t.text     "email_text"
    t.string   "zip"
    t.datetime "notification_sent"
  end

  create_table "pages", :force => true do |t|
    t.string   "title"
    t.string   "permalink"
    t.text     "body"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.text     "teaser"
  end

  add_index "pages", ["permalink"], :name => "index_pages_on_permalink"

  create_table "payment_notifications", :force => true do |t|
    t.text     "params"
    t.string   "status"
    t.string   "transaction_id"
    t.string   "transaction_type"
    t.integer  "user_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "purchases", :force => true do |t|
    t.integer  "user_id"
    t.integer  "issue_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "price_paid"
    t.datetime "purchase_date"
    t.string   "paypal_payer_id"
    t.string   "paypal_first_name"
    t.string   "paypal_last_name"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "settings", :force => true do |t|
    t.string   "var",                       :null => false
    t.text     "value"
    t.integer  "target_id"
    t.string   "target_type", :limit => 30
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "settings", ["target_type", "target_id", "var"], :name => "index_settings_on_target_type_and_target_id_and_var", :unique => true

  create_table "subscriptions", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.string   "paypal_payer_id"
    t.string   "paypal_profile_id"
    t.string   "paypal_first_name"
    t.string   "paypal_last_name"
    t.integer  "refund"
    t.string   "paypal_email"
    t.integer  "price_paid"
    t.datetime "purchase_date"
    t.datetime "cancellation_date"
    t.datetime "valid_from"
    t.integer  "duration"
    t.datetime "refunded_on"
    t.string   "paypal_street1"
    t.string   "paypal_street2"
    t.string   "paypal_city_name"
    t.string   "paypal_state_or_province"
    t.string   "paypal_country_name"
    t.string   "paypal_postal_code"
    t.boolean  "paper_copy"
    t.string   "paypal_country_code"
  end

  add_index "subscriptions", ["user_id"], :name => "index_subscriptions_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "username"
    t.boolean  "admin"
    t.boolean  "institution"
    t.integer  "parent_id"
    t.string   "ip_whitelist"
    t.string   "uk_id"
    t.datetime "uk_expiry"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
