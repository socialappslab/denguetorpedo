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

ActiveRecord::Schema.define(version: 20151216211551) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", id: false, force: :cascade do |t|
    t.integer  "id",                        default: "nextval('active_admin_comments_id_seq'::regclass)", null: false
    t.string   "resource_id",   limit: 255,                                                               null: false
    t.string   "resource_type", limit: 255,                                                               null: false
    t.integer  "author_id"
    t.string   "author_type",   limit: 255
    t.text     "body"
    t.datetime "created_at",                                                                              null: false
    t.datetime "updated_at",                                                                              null: false
    t.string   "namespace",     limit: 255
  end

  create_table "admin_users", id: false, force: :cascade do |t|
    t.integer  "id",                                 default: "nextval('admin_users_id_seq'::regclass)", null: false
    t.string   "email",                  limit: 255, default: "",                                        null: false
    t.string   "encrypted_password",     limit: 255, default: "",                                        null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0,                                         null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                                                             null: false
    t.datetime "updated_at",                                                                             null: false
  end

  create_table "badges", id: false, force: :cascade do |t|
    t.integer  "id",         default: "nextval('badges_id_seq'::regclass)", null: false
    t.integer  "user_id"
    t.integer  "prize_id"
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
  end

  create_table "breeding_sites", id: false, force: :cascade do |t|
    t.integer  "id",                            default: "nextval('breeding_sites_id_seq'::regclass)", null: false
    t.string   "description_in_pt", limit: 255
    t.string   "description_in_es", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "string_id",         limit: 255
    t.string   "code",              limit: 255
  end

  create_table "buy_ins", id: false, force: :cascade do |t|
    t.integer  "id",              default: "nextval('buy_ins_id_seq'::regclass)", null: false
    t.integer  "group_buy_in_id"
    t.integer  "user_id"
    t.datetime "created_at",                                                      null: false
    t.datetime "updated_at",                                                      null: false
    t.boolean  "accepted"
    t.boolean  "expired",         default: false,                                 null: false
  end

  create_table "cities", id: false, force: :cascade do |t|
    t.integer  "id",                             default: "nextval('cities_id_seq'::regclass)", null: false
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

  create_table "ckeditor_assets", force: :cascade do |t|
    t.string   "data_file_name",    limit: 255, null: false
    t.string   "data_content_type", limit: 255
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    limit: 30
    t.string   "type",              limit: 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], name: "idx_ckeditor_assetable", using: :btree
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], name: "idx_ckeditor_assetable_type", using: :btree

  create_table "comments", id: false, force: :cascade do |t|
    t.integer  "id",                           default: "nextval('comments_id_seq'::regclass)", null: false
    t.integer  "user_id"
    t.integer  "commentable_id"
    t.string   "commentable_type", limit: 255
    t.text     "content"
    t.datetime "created_at",                                                                    null: false
    t.datetime "updated_at",                                                                    null: false
    t.integer  "likes_count",                  default: 0
  end

  create_table "contacts", id: false, force: :cascade do |t|
    t.integer  "id",                     default: "nextval('contacts_id_seq'::regclass)", null: false
    t.string   "title",      limit: 255
    t.string   "email",      limit: 255
    t.string   "name",       limit: 255
    t.text     "message"
    t.datetime "created_at",                                                              null: false
    t.datetime "updated_at",                                                              null: false
  end

  create_table "conversations", id: false, force: :cascade do |t|
    t.integer  "id",         default: "nextval('conversations_id_seq'::regclass)", null: false
    t.text     "name"
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
  end

  create_table "conversations_users", id: false, force: :cascade do |t|
    t.integer "id",              default: "nextval('conversations_users_id_seq'::regclass)", null: false
    t.integer "conversation_id"
    t.integer "user_id"
  end

  create_table "countries", id: false, force: :cascade do |t|
    t.integer "id",               default: "nextval('countries_id_seq'::regclass)", null: false
    t.string  "name", limit: 255
  end

  create_table "csv_errors", id: false, force: :cascade do |t|
    t.integer  "id",            default: "nextval('csv_errors_id_seq'::regclass)", null: false
    t.integer  "csv_report_id"
    t.integer  "error_type"
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
    t.integer  "csv_id"
  end

  create_table "csv_reports", id: false, force: :cascade do |t|
    t.integer  "id",                           default: "nextval('csv_reports_id_seq'::regclass)", null: false
    t.text     "parsed_content"
    t.datetime "created_at",                                                                       null: false
    t.datetime "updated_at",                                                                       null: false
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
  end

  create_table "device_sessions", id: false, force: :cascade do |t|
    t.integer  "id",                       default: "nextval('device_sessions_id_seq'::regclass)", null: false
    t.integer  "user_id"
    t.string   "token",        limit: 255
    t.string   "device_name",  limit: 255
    t.string   "device_model", limit: 255
    t.datetime "created_at",                                                                       null: false
    t.datetime "updated_at",                                                                       null: false
  end

  create_table "documentation_sections", id: false, force: :cascade do |t|
    t.integer  "id",                        default: "nextval('documentation_sections_id_seq'::regclass)", null: false
    t.string   "title",         limit: 255
    t.text     "content"
    t.integer  "editor_id"
    t.integer  "creator_id"
    t.datetime "created_at",                                                                               null: false
    t.datetime "updated_at",                                                                               null: false
    t.integer  "order_id"
    t.string   "title_in_es",   limit: 255
    t.text     "content_in_es"
  end

  create_table "elimination_methods", id: false, force: :cascade do |t|
    t.integer  "id",                              default: "nextval('elimination_methods_id_seq'::regclass)", null: false
    t.string   "method",              limit: 255
    t.integer  "points"
    t.datetime "created_at",                                                                                  null: false
    t.datetime "updated_at",                                                                                  null: false
    t.integer  "elimination_type_id"
    t.integer  "breeding_site_id"
    t.string   "description_in_pt",   limit: 255
    t.string   "description_in_es",   limit: 255
  end

  create_table "elimination_types", id: false, force: :cascade do |t|
    t.integer  "id",                     default: "nextval('elimination_types_id_seq'::regclass)", null: false
    t.string   "name",       limit: 255
    t.integer  "points"
    t.datetime "created_at",                                                                       null: false
    t.datetime "updated_at",                                                                       null: false
  end

  create_table "feedbacks", id: false, force: :cascade do |t|
    t.integer  "id",                     default: "nextval('feedbacks_id_seq'::regclass)", null: false
    t.string   "title",      limit: 255
    t.string   "email",      limit: 255
    t.string   "name",       limit: 255
    t.text     "message"
    t.datetime "created_at",                                                               null: false
    t.datetime "updated_at",                                                               null: false
  end

  create_table "feeds", id: false, force: :cascade do |t|
    t.integer  "id",                       default: "nextval('feeds_id_seq'::regclass)", null: false
    t.string   "target_type",  limit: 255
    t.integer  "target_id"
    t.datetime "created_at",                                                             null: false
    t.datetime "updated_at",                                                             null: false
    t.integer  "user_id"
    t.integer  "feed_type_cd"
  end

  create_table "houses", id: false, force: :cascade do |t|
    t.integer  "id",                                     default: "nextval('houses_id_seq'::regclass)", null: false
    t.datetime "created_at",                                                                            null: false
    t.datetime "updated_at",                                                                            null: false
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

  create_table "inspections", id: false, force: :cascade do |t|
    t.integer "id",                  default: "nextval('inspections_id_seq'::regclass)", null: false
    t.integer "visit_id"
    t.integer "report_id"
    t.integer "identification_type"
    t.integer "position",            default: 0
    t.integer "csv_id"
  end

  create_table "likes", id: false, force: :cascade do |t|
    t.integer  "id",                        default: "nextval('likes_id_seq'::regclass)", null: false
    t.integer  "user_id"
    t.integer  "likeable_id"
    t.string   "likeable_type", limit: 255
    t.datetime "created_at",                                                              null: false
    t.datetime "updated_at",                                                              null: false
  end

  create_table "location_statuses", id: false, force: :cascade do |t|
    t.integer  "id",                              default: "nextval('location_statuses_id_seq'::regclass)", null: false
    t.integer  "location_id"
    t.integer  "status"
    t.datetime "created_at",                                                                                null: false
    t.datetime "updated_at",                                                                                null: false
    t.integer  "dengue_count"
    t.integer  "chik_count"
    t.string   "health_report",       limit: 255
    t.integer  "identification_type"
    t.datetime "identified_at"
    t.datetime "cleaned_at"
  end

  create_table "locations", id: false, force: :cascade do |t|
    t.integer  "id",                          default: "nextval('locations_id_seq'::regclass)", null: false
    t.string   "address",         limit: 255
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at",                                                                    null: false
    t.datetime "updated_at",                                                                    null: false
    t.integer  "neighborhood_id"
    t.string   "street_type",     limit: 255, default: ""
    t.string   "street_name",     limit: 255, default: ""
    t.string   "street_number",   limit: 255, default: ""
  end

  create_table "messages", id: false, force: :cascade do |t|
    t.integer  "id",              default: "nextval('messages_id_seq'::regclass)", null: false
    t.text     "body"
    t.integer  "user_id"
    t.integer  "conversation_id"
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
  end

  create_table "neighborhoods", id: false, force: :cascade do |t|
    t.integer  "id",                             default: "nextval('neighborhoods_id_seq'::regclass)", null: false
    t.string   "name",               limit: 255
    t.datetime "created_at",                                                                           null: false
    t.datetime "updated_at",                                                                           null: false
    t.string   "photo_file_name",    limit: 255
    t.string   "photo_content_type", limit: 255
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.integer  "city_id"
    t.float    "latitude"
    t.float    "longitude"
  end

  create_table "notices", id: false, force: :cascade do |t|
    t.integer  "id",                             default: "nextval('notices_id_seq'::regclass)", null: false
    t.string   "title",              limit: 255, default: ""
    t.text     "description",                    default: ""
    t.string   "location",           limit: 255, default: ""
    t.datetime "date"
    t.integer  "neighborhood_id"
    t.integer  "user_id"
    t.datetime "created_at",                                                                     null: false
    t.datetime "updated_at",                                                                     null: false
    t.string   "photo_file_name",    limit: 255
    t.string   "photo_content_type", limit: 255
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.text     "summary",                        default: ""
    t.string   "institution_name",   limit: 255
  end

  create_table "notifications", id: false, force: :cascade do |t|
    t.integer  "id",                     default: "nextval('notifications_id_seq'::regclass)", null: false
    t.string   "phone",      limit: 255
    t.text     "text"
    t.string   "board",      limit: 255
    t.datetime "created_at",                                                                   null: false
    t.datetime "updated_at",                                                                   null: false
    t.boolean  "read",                   default: false
  end

  create_table "posts", id: false, force: :cascade do |t|
    t.integer  "id",                             default: "nextval('posts_id_seq'::regclass)", null: false
    t.integer  "user_id"
    t.string   "title",              limit: 255
    t.text     "content"
    t.datetime "created_at",                                                                   null: false
    t.datetime "updated_at",                                                                   null: false
    t.integer  "neighborhood_id"
    t.integer  "likes_count",                    default: 0
    t.string   "photo_file_name",    limit: 255
    t.string   "photo_content_type", limit: 255
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
  end

  create_table "prize_codes", id: false, force: :cascade do |t|
    t.integer  "id",                      default: "nextval('prize_codes_id_seq'::regclass)", null: false
    t.integer  "user_id"
    t.integer  "prize_id"
    t.datetime "expire_by"
    t.string   "code",        limit: 255
    t.datetime "created_at",                                                                  null: false
    t.datetime "updated_at",                                                                  null: false
    t.boolean  "redeemed",                default: false,                                     null: false
    t.boolean  "expired",                 default: false,                                     null: false
    t.datetime "obtained_on"
  end

  create_table "prizes", id: false, force: :cascade do |t|
    t.integer  "id",                                   default: "nextval('prizes_id_seq'::regclass)", null: false
    t.string   "prize_name",               limit: 255
    t.integer  "cost"
    t.integer  "stock"
    t.integer  "user_id"
    t.text     "description"
    t.text     "redemption_directions"
    t.datetime "expire_on"
    t.datetime "created_at",                                                                          null: false
    t.datetime "updated_at",                                                                          null: false
    t.string   "prize_photo_file_name",    limit: 255
    t.string   "prize_photo_content_type", limit: 255
    t.integer  "prize_photo_file_size"
    t.datetime "prize_photo_updated_at"
    t.boolean  "community_prize",                      default: false,                                null: false
    t.boolean  "self_prize",                           default: false,                                null: false
    t.boolean  "is_badge",                             default: false,                                null: false
    t.boolean  "prazo",                                default: true
    t.integer  "neighborhood_id"
    t.integer  "team_id"
  end

  create_table "recruitments", id: false, force: :cascade do |t|
    t.integer  "id",           default: "nextval('recruitments_id_seq'::regclass)", null: false
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.integer  "recruiter_id"
    t.integer  "recruitee_id"
  end

  create_table "reports", id: false, force: :cascade do |t|
    t.integer  "id",                                    default: "nextval('reports_id_seq'::regclass)", null: false
    t.text     "report"
    t.integer  "reporter_id"
    t.datetime "created_at",                                                                            null: false
    t.datetime "updated_at",                                                                            null: false
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
  end

  create_table "reports_users", id: false, force: :cascade do |t|
    t.integer "report_id"
    t.integer "user_id"
  end

  create_table "team_memberships", id: false, force: :cascade do |t|
    t.integer  "id",         default: "nextval('team_memberships_id_seq'::regclass)", null: false
    t.integer  "user_id"
    t.integer  "team_id"
    t.boolean  "verified"
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
  end

  create_table "teams", id: false, force: :cascade do |t|
    t.integer  "id",                                     default: "nextval('teams_id_seq'::regclass)", null: false
    t.string   "name",                       limit: 255
    t.integer  "neighborhood_id"
    t.string   "profile_photo_file_name",    limit: 255
    t.string   "profile_photo_content_type", limit: 255
    t.integer  "profile_photo_file_size"
    t.datetime "profile_photo_updated_at"
    t.datetime "created_at",                                                                           null: false
    t.datetime "updated_at",                                                                           null: false
    t.boolean  "blocked"
    t.integer  "points",                                 default: 0
  end

  create_table "user_notifications", id: false, force: :cascade do |t|
    t.integer  "id",                            default: "nextval('user_notifications_id_seq'::regclass)", null: false
    t.integer  "user_id"
    t.string   "notification_type", limit: 255
    t.integer  "notification_id"
    t.datetime "notified_at"
    t.datetime "seen_at"
    t.integer  "medium"
  end

  create_table "users", id: false, force: :cascade do |t|
    t.integer  "id",                                     default: "nextval('users_id_seq'::regclass)", null: false
    t.string   "username",                   limit: 255
    t.string   "password_digest",            limit: 255
    t.string   "auth_token",                 limit: 255
    t.datetime "created_at",                                                                           null: false
    t.datetime "updated_at",                                                                           null: false
    t.string   "email",                      limit: 255
    t.string   "password_reset_token",       limit: 255
    t.datetime "password_reset_sent_at"
    t.string   "phone_number",               limit: 255
    t.integer  "points",                                 default: 0,                                   null: false
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

  create_table "visits", id: false, force: :cascade do |t|
    t.integer  "id",                          default: "nextval('visits_id_seq'::regclass)", null: false
    t.integer  "location_id"
    t.integer  "dengue_count"
    t.integer  "chik_count"
    t.string   "health_report",   limit: 255
    t.datetime "visited_at"
    t.integer  "parent_visit_id"
    t.integer  "csv_id"
  end

end
