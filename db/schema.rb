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

ActiveRecord::Schema.define(version: 20190618032630) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "resource_id",   limit: 255, null: false
    t.string   "resource_type", limit: 255, null: false
    t.integer  "author_id"
    t.string   "author_type",   limit: 255
    t.text     "body"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "namespace",     limit: 255
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_admin_notes_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "assignments", force: :cascade do |t|
    t.string   "task"
    t.integer  "city_block_id"
    t.datetime "date"
    t.string   "status",        default: "pendiente"
    t.text     "notes"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "assignments", ["city_block_id"], name: "index_assignments_on_city_block_id", using: :btree

  create_table "assignments_users", id: false, force: :cascade do |t|
    t.integer "assignment_id", null: false
    t.integer "user_id",       null: false
  end

  create_table "breeding_sites", force: :cascade do |t|
    t.string   "description_in_pt", limit: 255
    t.string   "description_in_es", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "string_id",         limit: 255
    t.string   "code",              limit: 255
  end

  create_table "cities", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.string   "state",              limit: 255
    t.string   "state_code",         limit: 255
    t.integer  "country_id"
    t.string   "photo_file_name",    limit: 255
    t.string   "photo_content_type", limit: 255
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "time_zone",          limit: 255
    t.string   "country",            limit: 255
  end

  create_table "city_blocks", force: :cascade do |t|
    t.string  "name"
    t.integer "neighborhood_id"
    t.integer "district_id"
    t.integer "city_id"
    t.text    "polygon"
  end

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "commentable_id"
    t.string   "commentable_type", limit: 255
    t.text     "content"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "likes_count",                  default: 0
  end

  add_index "comments", ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type", using: :btree

  create_table "conversations", force: :cascade do |t|
    t.text     "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "conversations_users", force: :cascade do |t|
    t.integer "conversation_id"
    t.integer "user_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name", limit: 255
  end

  create_table "csv_errors", force: :cascade do |t|
    t.integer  "csv_report_id"
    t.integer  "error_type"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "csv_id"
  end

  create_table "csv_reports", force: :cascade do |t|
    t.text     "parsed_content"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "csv_file_name",    limit: 255
    t.string   "csv_content_type", limit: 255
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
    t.text     "source"
    t.boolean  "contains_photo_urls",      default: false
    t.boolean  "username_per_inspections", default: false
  end

  create_table "device_sessions", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "token",        limit: 255
    t.string   "device_name",  limit: 255
    t.string   "device_model", limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "districts", force: :cascade do |t|
    t.string  "name"
    t.integer "city_id"
  end

  create_table "documentation_sections", force: :cascade do |t|
    t.string   "title",         limit: 255
    t.text     "content"
    t.integer  "editor_id"
    t.integer  "creator_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "order_id"
    t.string   "title_in_es",   limit: 255
    t.text     "content_in_es"
  end

  create_table "elimination_methods", force: :cascade do |t|
    t.string   "method",              limit: 255
    t.integer  "points"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "elimination_type_id"
    t.integer  "breeding_site_id"
    t.string   "description_in_pt",   limit: 255
    t.string   "description_in_es",   limit: 255
  end

  create_table "elimination_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "points"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "houses", force: :cascade do |t|
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.string   "name",                       limit: 255
    t.integer  "featured_event_id"
    t.integer  "location_id"
    t.string   "profile_photo_file_name",    limit: 255
    t.string   "profile_photo_content_type", limit: 255
    t.integer  "profile_photo_file_size"
    t.datetime "profile_photo_updated_at"
    t.string   "phone_number",               limit: 255, default: ""
    t.string   "house_type",                 limit: 255, default: "morador"
    t.integer  "neighborhood_id"
  end

  create_table "inspections", force: :cascade do |t|
    t.integer  "visit_id"
    t.integer  "report_id"
    t.integer  "identification_type"
    t.integer  "position",                       default: 0
    t.integer  "csv_id"
    t.string   "source"
    t.datetime "last_synced_at"
    t.integer  "last_sync_seq"
    t.integer  "reporter_id"
    t.integer  "eliminator_id"
    t.integer  "location_id"
    t.integer  "breeding_site_id"
    t.integer  "elimination_method_id"
    t.text     "description"
    t.boolean  "protected"
    t.boolean  "chemically_treated"
    t.boolean  "larvae"
    t.boolean  "pupae"
    t.string   "field_identifier"
    t.string   "before_photo_file_name"
    t.string   "before_photo_content_type"
    t.integer  "before_photo_file_size"
    t.datetime "before_photo_updated_at"
    t.string   "after_photo_file_name"
    t.string   "after_photo_content_type"
    t.integer  "after_photo_file_size"
    t.datetime "after_photo_updated_at"
    t.datetime "inspected_at"
    t.datetime "eliminated_at"
    t.string   "csv_uuid"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "verified_at"
    t.integer  "likes_count",                    default: 0
    t.integer  "verifier_id"
    t.integer  "resolved_verifier_id"
    t.datetime "completed_at"
    t.integer  "previous_similar_inspection_id"
  end

  create_table "likes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "likeable_id"
    t.string   "likeable_type", limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "likes", ["likeable_id", "likeable_type"], name: "index_likes_on_likeable_id_and_likeable_type", using: :btree
  add_index "likes", ["user_id", "likeable_id", "likeable_type"], name: "index_likes_on_user_id_and_likeable_id_and_likeable_type", unique: true, using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "address",         limit: 255
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "neighborhood_id"
    t.string   "street_type",     limit: 255, default: ""
    t.string   "street_name",     limit: 255, default: ""
    t.string   "street_number",   limit: 255, default: ""
    t.json     "questions"
    t.string   "source"
    t.datetime "last_synced_at"
    t.integer  "last_sync_seq"
    t.string   "pouchdb_id"
    t.integer  "city_block_id"
    t.integer  "city_id"
    t.string   "location_type"
  end

  add_index "locations", ["city_block_id"], name: "index_locations_on_city_block_id", using: :btree
  add_index "locations", ["city_id"], name: "index_locations_on_city_id", using: :btree

  create_table "memberships", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "user_id"
    t.string   "role",            default: "morador"
    t.boolean  "blocked",         default: false
    t.boolean  "active",          default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "memberships", ["organization_id", "user_id"], name: "index_memberships_on_organization_id_and_user_id", unique: true, using: :btree
  add_index "memberships", ["organization_id"], name: "index_memberships_on_organization_id", using: :btree
  add_index "memberships", ["user_id"], name: "index_memberships_on_user_id", using: :btree

  create_table "messages", force: :cascade do |t|
    t.text     "body"
    t.integer  "user_id"
    t.integer  "conversation_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "neighborhoods", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "photo_file_name",    limit: 255
    t.string   "photo_content_type", limit: 255
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "city_id"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "district_id"
  end

  add_index "neighborhoods", ["district_id"], name: "index_neighborhoods_on_district_id", using: :btree

  create_table "notices", force: :cascade do |t|
    t.string   "title",              limit: 255, default: ""
    t.text     "description",                    default: ""
    t.string   "location",           limit: 255, default: ""
    t.datetime "date"
    t.integer  "neighborhood_id"
    t.integer  "user_id"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.string   "photo_file_name",    limit: 255
    t.string   "photo_content_type", limit: 255
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.text     "summary",                        default: ""
    t.string   "institution_name",   limit: 255
  end

  create_table "notifications", force: :cascade do |t|
    t.string   "phone",      limit: 255
    t.text     "text"
    t.string   "board",      limit: 255
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "read",                   default: false
  end

  create_table "organizations", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb    "breeding_sites_codes"
  end

  create_table "parameters", force: :cascade do |t|
    t.integer "organization_id"
    t.string  "key"
    t.text    "value"
  end

  create_table "posts", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "title",              limit: 255
    t.text     "content"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "neighborhood_id"
    t.integer  "likes_count",                    default: 0
    t.string   "photo_file_name",    limit: 255
    t.string   "photo_content_type", limit: 255
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
    t.string   "code",        limit: 255
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.boolean  "redeemed",                default: false, null: false
    t.boolean  "expired",                 default: false, null: false
    t.datetime "obtained_on"
  end

  create_table "prizes", force: :cascade do |t|
    t.string   "prize_name",               limit: 255
    t.integer  "cost"
    t.integer  "stock"
    t.integer  "user_id"
    t.text     "description"
    t.text     "redemption_directions"
    t.datetime "expire_on"
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.string   "prize_photo_file_name",    limit: 255
    t.string   "prize_photo_content_type", limit: 255
    t.integer  "prize_photo_file_size"
    t.datetime "prize_photo_updated_at"
    t.boolean  "community_prize",                      default: false, null: false
    t.boolean  "self_prize",                           default: false, null: false
    t.boolean  "is_badge",                             default: false, null: false
    t.boolean  "prazo",                                default: true
    t.integer  "neighborhood_id"
    t.integer  "team_id"
  end

  create_table "recruitments", force: :cascade do |t|
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "recruiter_id"
    t.integer  "recruitee_id"
  end

  create_table "reports", force: :cascade do |t|
    t.text     "report"
    t.integer  "reporter_id"
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.integer  "status_cd"
    t.integer  "eliminator_id"
    t.integer  "location_id"
    t.string   "before_photo_file_name",    limit: 255
    t.string   "before_photo_content_type", limit: 255
    t.integer  "before_photo_file_size"
    t.datetime "before_photo_updated_at"
    t.string   "after_photo_file_name",     limit: 255
    t.string   "after_photo_content_type",  limit: 255
    t.integer  "after_photo_file_size"
    t.datetime "after_photo_updated_at"
    t.datetime "eliminated_at"
    t.string   "isVerified",                limit: 255
    t.integer  "verifier_id"
    t.datetime "verified_at"
    t.integer  "resolved_verifier_id"
    t.datetime "resolved_verified_at"
    t.string   "is_resolved_verified",      limit: 255
    t.boolean  "sms",                                   default: false
    t.string   "verifier_name",             limit: 255, default: ""
    t.datetime "completed_at"
    t.datetime "credited_at"
    t.boolean  "is_credited"
    t.integer  "feed_type_cd"
    t.integer  "neighborhood_id"
    t.integer  "breeding_site_id"
    t.integer  "elimination_method_id"
    t.integer  "csv_report_id"
    t.string   "csv_uuid",                  limit: 255
    t.boolean  "protected"
    t.boolean  "chemically_treated"
    t.boolean  "larvae"
    t.boolean  "pupae"
    t.integer  "likes_count",                           default: 0
    t.string   "field_identifier",          limit: 255
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "team_memberships", ["user_id", "team_id"], name: "index_team_memberships_on_user_id_and_team_id", unique: true, using: :btree

  create_table "teams", force: :cascade do |t|
    t.string   "name",                       limit: 255
    t.integer  "neighborhood_id"
    t.string   "profile_photo_file_name",    limit: 255
    t.string   "profile_photo_content_type", limit: 255
    t.integer  "profile_photo_file_size"
    t.datetime "profile_photo_updated_at"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "blocked"
    t.integer  "points",                                 default: 0
    t.integer  "organization_id"
  end

  add_index "teams", ["organization_id"], name: "index_teams_on_organization_id", using: :btree

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
    t.string   "notification_type", limit: 255
    t.integer  "notification_id"
    t.datetime "notified_at"
    t.datetime "seen_at"
    t.integer  "medium"
  end

  add_index "user_notifications", ["seen_at"], name: "index_user_notifications_on_seen_at", using: :btree
  add_index "user_notifications", ["user_id"], name: "index_user_notifications_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "username",                   limit: 255
    t.string   "password_digest",            limit: 255
    t.string   "auth_token",                 limit: 255
    t.datetime "created_at",                                                         null: false
    t.datetime "updated_at",                                                         null: false
    t.string   "email",                      limit: 255
    t.string   "password_reset_token",       limit: 255
    t.datetime "password_reset_sent_at"
    t.string   "phone_number",               limit: 255
    t.integer  "points",                                 default: 0,                 null: false
    t.integer  "house_id"
    t.string   "profile_photo_file_name",    limit: 255
    t.string   "profile_photo_content_type", limit: 255
    t.integer  "profile_photo_file_size"
    t.datetime "profile_photo_updated_at"
    t.boolean  "is_verifier",                            default: false
    t.boolean  "is_fully_registered",                    default: false
    t.boolean  "is_health_agent",                        default: false
    t.string   "first_name",                 limit: 255, default: ""
    t.string   "middle_name",                limit: 255, default: ""
    t.string   "last_name",                  limit: 255, default: ""
    t.string   "nickname",                   limit: 255, default: ""
    t.string   "display",                    limit: 255, default: "firstmiddlelast"
    t.string   "role",                       limit: 255, default: "morador"
    t.integer  "total_points",                           default: 0
    t.boolean  "gender",                                 default: true
    t.boolean  "is_blocked",                             default: false
    t.string   "carrier",                    limit: 255, default: ""
    t.boolean  "prepaid"
    t.integer  "neighborhood_id"
    t.string   "locale",                     limit: 255
    t.string   "name",                       limit: 255
  end

  add_index "users", ["auth_token"], name: "index_users_on_auth_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "visits", force: :cascade do |t|
    t.integer  "location_id"
    t.integer  "dengue_count"
    t.integer  "chik_count"
    t.string   "health_report",   limit: 255
    t.datetime "visited_at"
    t.integer  "parent_visit_id"
    t.integer  "csv_id"
    t.string   "source"
    t.datetime "last_synced_at"
    t.integer  "last_sync_seq"
    t.string   "pouchdb_id"
    t.json     "questions"
  end

  add_foreign_key "assignments", "city_blocks"
end
