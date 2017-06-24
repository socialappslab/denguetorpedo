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

ActiveRecord::Schema.define(version: 20170318222754) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: :cascade do |t|
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
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "breeding_sites", force: :cascade do |t|
    t.string   "description_in_pt"
    t.string   "description_in_es"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "string_id"
    t.string   "code"
  end

  create_table "cities", force: :cascade do |t|
    t.string   "name"
    t.string   "state"
    t.string   "state_code"
    t.integer  "country_id"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "time_zone"
    t.string   "country"
  end

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "likes_count",      default: 0
  end

  add_index "comments", ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type", using: :btree

  create_table "conversations", force: :cascade do |t|
    t.text     "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "conversations_users", force: :cascade do |t|
    t.integer "conversation_id"
    t.integer "user_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
  end

  create_table "csv_errors", force: :cascade do |t|
    t.integer  "csv_report_id"
    t.integer  "error_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "csv_id"
  end

  create_table "csv_reports", force: :cascade do |t|
    t.text     "parsed_content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "csv_file_name"
    t.string   "csv_content_type"
    t.integer  "csv_file_size"
    t.datetime "csv_updated_at"
    t.integer  "user_id"
    t.integer  "location_id"
    t.datetime "parsed_at"
    t.datetime "verified_at"
    t.integer  "neighborhood_id"
  end

  create_table "csvs", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "location_id"
    t.datetime "parsed_at"
    t.datetime "verified_at"
    t.string   "csv_file_name"
    t.string   "csv_content_type"
    t.integer  "csv_file_size"
    t.datetime "csv_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "device_sessions", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "token"
    t.string   "device_name"
    t.string   "device_model"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "documentation_sections", force: :cascade do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "editor_id"
    t.integer  "creator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id"
    t.string   "title_in_es"
    t.text     "content_in_es"
  end

  create_table "elimination_methods", force: :cascade do |t|
    t.string   "method"
    t.integer  "points"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "elimination_type_id"
    t.integer  "breeding_site_id"
    t.string   "description_in_pt"
    t.string   "description_in_es"
  end

  create_table "elimination_types", force: :cascade do |t|
    t.string   "name"
    t.integer  "points"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "houses", force: :cascade do |t|
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.integer  "location_id"
    t.string   "profile_photo_file_name"
    t.string   "profile_photo_content_type"
    t.integer  "profile_photo_file_size"
    t.datetime "profile_photo_updated_at"
    t.string   "phone_number",               default: ""
    t.string   "house_type",                 default: "morador"
    t.integer  "neighborhood_id"
  end

  create_table "inspections", force: :cascade do |t|
    t.integer  "visit_id"
    t.integer  "report_id"
    t.integer  "identification_type"
    t.integer  "position",            default: 0
    t.integer  "csv_id"
    t.string   "source"
    t.datetime "last_synced_at"
    t.integer  "last_sync_seq"
  end

  create_table "likes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "likeable_id"
    t.string   "likeable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "likes", ["likeable_id", "likeable_type"], name: "index_likes_on_likeable_id_and_likeable_type", using: :btree
  add_index "likes", ["user_id", "likeable_id", "likeable_type"], name: "index_likes_on_user_id_and_likeable_id_and_likeable_type", unique: true, using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "address"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "neighborhood_id"
    t.string   "street_type",     default: ""
    t.string   "street_name",     default: ""
    t.string   "street_number",   default: ""
    t.json     "questions"
    t.string   "source"
    t.datetime "last_synced_at"
    t.integer  "last_sync_seq"
    t.string   "pouchdb_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text     "body"
    t.integer  "user_id"
    t.integer  "conversation_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "neighborhoods", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "city_id"
    t.float    "latitude"
    t.float    "longitude"
  end

  create_table "notices", force: :cascade do |t|
    t.string   "title",              default: ""
    t.text     "description",        default: ""
    t.string   "location",           default: ""
    t.datetime "date"
    t.integer  "neighborhood_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.text     "summary",            default: ""
    t.string   "institution_name"
  end

  create_table "notifications", force: :cascade do |t|
    t.string   "phone"
    t.text     "text"
    t.string   "board"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "read",       default: false
  end

  create_table "posts", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "title"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "neighborhood_id"
    t.integer  "likes_count",        default: 0
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.datetime "last_synced_at"
    t.integer  "last_sync_seq"
  end

  add_index "posts", ["user_id"], name: "index_posts_on_user_id", using: :btree

  create_table "prize_codes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "prize_id"
    t.datetime "expire_by"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "redeemed",    default: false, null: false
    t.boolean  "expired",     default: false, null: false
    t.datetime "obtained_on"
  end

  create_table "prizes", force: :cascade do |t|
    t.string   "prize_name"
    t.integer  "cost"
    t.integer  "stock"
    t.integer  "user_id"
    t.text     "description"
    t.text     "redemption_directions"
    t.datetime "expire_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "prize_photo_file_name"
    t.string   "prize_photo_content_type"
    t.integer  "prize_photo_file_size"
    t.datetime "prize_photo_updated_at"
    t.boolean  "community_prize",          default: false, null: false
    t.boolean  "self_prize",               default: false, null: false
    t.boolean  "is_badge",                 default: false, null: false
    t.boolean  "prazo",                    default: true
    t.integer  "neighborhood_id"
    t.integer  "team_id"
  end

  create_table "recruitments", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "recruiter_id"
    t.integer  "recruitee_id"
  end

  create_table "reports", force: :cascade do |t|
    t.string   "nation"
    t.string   "state"
    t.string   "city"
    t.string   "address"
    t.string   "neighborhood"
    t.text     "report"
    t.integer  "reporter_id"
    t.integer  "status_cd"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "eliminator_id"
    t.integer  "location_id"
    t.string   "before_photo_file_name"
    t.string   "before_photo_content_type"
    t.integer  "before_photo_file_size"
    t.datetime "before_photo_updated_at"
    t.string   "after_photo_file_name"
    t.string   "after_photo_content_type"
    t.integer  "after_photo_file_size"
    t.datetime "after_photo_updated_at"
    t.datetime "eliminated_at"
    t.string   "isVerified"
    t.integer  "verifier_id"
    t.datetime "verified_at"
    t.integer  "resolved_verifier_id"
    t.datetime "resolved_verified_at"
    t.string   "is_resolved_verified"
    t.boolean  "sms",                       default: false
    t.string   "verifier_name",             default: ""
    t.datetime "completed_at"
    t.datetime "credited_at"
    t.boolean  "is_credited"
    t.integer  "feed_type_cd"
    t.integer  "neighborhood_id"
    t.integer  "breeding_site_id"
    t.integer  "elimination_method_id"
    t.integer  "csv_report_id"
    t.string   "csv_uuid"
    t.boolean  "protected"
    t.boolean  "chemically_treated"
    t.boolean  "larvae"
    t.boolean  "pupae"
    t.integer  "likes_count",               default: 0
    t.string   "field_identifier"
    t.integer  "csv_id"
    t.string   "source"
    t.datetime "last_synced_at"
    t.integer  "last_sync_seq"
  end

  add_index "reports", ["eliminator_id"], name: "index_reports_on_eliminator_id", using: :btree
  add_index "reports", ["reporter_id"], name: "index_reports_on_reporter_id", using: :btree

  create_table "reports_users", id: false, force: :cascade do |t|
    t.integer "report_id"
    t.integer "user_id"
  end

  create_table "team_memberships", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "team_id"
    t.boolean  "verified"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "team_memberships", ["user_id", "team_id"], name: "index_team_memberships_on_user_id_and_team_id", unique: true, using: :btree

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.integer  "neighborhood_id"
    t.string   "profile_photo_file_name"
    t.string   "profile_photo_content_type"
    t.integer  "profile_photo_file_size"
    t.datetime "profile_photo_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "blocked"
    t.integer  "points",                     default: 0
  end

  create_table "user_locations", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "location_id"
    t.datetime "assigned_at"
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_locations", ["user_id", "location_id"], name: "index_user_locations_on_user_id_and_location_id", unique: true, using: :btree

  create_table "user_notifications", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "notification_type"
    t.integer  "notification_id"
    t.datetime "notified_at"
    t.datetime "seen_at"
    t.integer  "medium"
  end

  add_index "user_notifications", ["seen_at"], name: "index_user_notifications_on_seen_at", using: :btree
  add_index "user_notifications", ["user_id"], name: "index_user_notifications_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "username"
    t.string   "password_digest"
    t.string   "auth_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.string   "phone_number"
    t.integer  "points",                     default: 0,                 null: false
    t.integer  "house_id"
    t.string   "profile_photo_file_name"
    t.string   "profile_photo_content_type"
    t.integer  "profile_photo_file_size"
    t.datetime "profile_photo_updated_at"
    t.boolean  "is_verifier",                default: false
    t.boolean  "is_fully_registered",        default: false
    t.boolean  "is_health_agent",            default: false
    t.string   "first_name",                 default: ""
    t.string   "middle_name",                default: ""
    t.string   "last_name",                  default: ""
    t.string   "nickname",                   default: ""
    t.string   "display",                    default: "firstmiddlelast"
    t.string   "role",                       default: "morador"
    t.integer  "total_points",               default: 0
    t.boolean  "gender",                     default: true
    t.boolean  "is_blocked",                 default: false
    t.string   "carrier",                    default: ""
    t.boolean  "prepaid"
    t.integer  "neighborhood_id"
    t.string   "locale"
    t.string   "name"
  end

  add_index "users", ["auth_token"], name: "index_users_on_auth_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "visits", force: :cascade do |t|
    t.integer  "location_id"
    t.integer  "dengue_count"
    t.integer  "chik_count"
    t.string   "health_report"
    t.datetime "visited_at"
    t.integer  "parent_visit_id"
    t.integer  "csv_id"
    t.string   "source"
    t.datetime "last_synced_at"
    t.integer  "last_sync_seq"
    t.string   "pouchdb_id"
  end

end
