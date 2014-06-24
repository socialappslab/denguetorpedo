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

ActiveRecord::Schema.define(:version => 20140620202612) do

  create_table "comments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.text     "content"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "contacts", :force => true do |t|
    t.string   "title"
    t.string   "email"
    t.string   "name"
    t.text     "message"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "documentation_sections", :force => true do |t|
    t.string   "title"
    t.text     "content"
    t.integer  "editor_id"
    t.integer  "creator_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "order_id"
  end

  create_table "elimination_methods", :force => true do |t|
    t.string   "method"
    t.integer  "points"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.integer  "elimination_type_id"
  end

  create_table "elimination_types", :force => true do |t|
    t.string   "name"
    t.integer  "points"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "feedbacks", :force => true do |t|
    t.string   "title"
    t.string   "email"
    t.string   "name"
    t.text     "message"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "feeds", :force => true do |t|
    t.string   "target_type"
    t.integer  "target_id"
    t.string   "feed_type"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "user_id"
    t.integer  "feed_type_cd"
  end

  create_table "houses", :force => true do |t|
    t.string   "address"
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
    t.string   "name"
    t.integer  "location_id"
    t.string   "profile_photo_file_name"
    t.string   "profile_photo_content_type"
    t.integer  "profile_photo_file_size"
    t.datetime "profile_photo_updated_at"
    t.string   "phone_number",               :default => ""
    t.string   "house_type",                 :default => "morador"
    t.integer  "neighborhood_id"
  end

  create_table "likes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "likeable_id"
    t.string   "likeable_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "likes", ["user_id", "likeable_id", "likeable_type"], :name => "index_likes_on_user_id_and_likeable_id_and_likeable_type", :unique => true

  create_table "locations", :force => true do |t|
    t.string   "address"
    t.float    "latitude"
    t.float    "longitude"
    t.boolean  "gmaps"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.string   "formatted_address"
    t.integer  "neighborhood_id"
    t.string   "street_type",       :default => ""
    t.string   "street_name",       :default => ""
    t.string   "street_number",     :default => ""
  end

  create_table "neighborhoods", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "coordinator_id"
  end

  create_table "notices", :force => true do |t|
    t.string   "title",              :default => ""
    t.text     "description",        :default => ""
    t.string   "location",           :default => ""
    t.datetime "date"
    t.integer  "neighborhood_id"
    t.integer  "user_id"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.text     "summary",            :default => ""
    t.string   "institution_name"
  end

  create_table "notifications", :force => true do |t|
    t.string   "phone"
    t.text     "text"
    t.string   "board"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.boolean  "read",       :default => false
  end

  create_table "posts", :force => true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.text     "content"
    t.integer  "type_cd"
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "wall_id"
    t.string   "wall_type"
  end

  add_index "posts", ["user_id"], :name => "index_posts_on_user_id"

  create_table "prize_codes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "prize_id"
    t.datetime "expire_by"
    t.string   "code"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "redeemed",    :default => false, :null => false
    t.boolean  "expired",     :default => false, :null => false
    t.datetime "obtained_on"
  end

  create_table "prizes", :force => true do |t|
    t.string   "prize_name"
    t.integer  "cost"
    t.integer  "stock"
    t.integer  "user_id"
    t.text     "description"
    t.text     "redemption_directions"
    t.datetime "expire_on"
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.string   "prize_photo_file_name"
    t.string   "prize_photo_content_type"
    t.integer  "prize_photo_file_size"
    t.datetime "prize_photo_updated_at"
    t.boolean  "community_prize",          :default => false, :null => false
    t.boolean  "self_prize",               :default => false, :null => false
    t.boolean  "is_badge",                 :default => false, :null => false
    t.boolean  "prazo",                    :default => true
    t.integer  "neighborhood_id"
  end

  create_table "recruitments", :force => true do |t|
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "recruiter_id"
    t.integer  "recruitee_id"
  end

  create_table "reports", :force => true do |t|
    t.string   "nation"
    t.string   "state"
    t.string   "city"
    t.string   "address"
    t.string   "neighborhood"
    t.text     "report"
    t.integer  "reporter_id"
    t.integer  "status_cd"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
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
    t.string   "elimination_type"
    t.string   "elimination_method"
    t.string   "isVerified"
    t.integer  "verifier_id"
    t.datetime "verified_at"
    t.integer  "resolved_verifier_id"
    t.datetime "resolved_verified_at"
    t.string   "is_resolved_verified"
    t.boolean  "sms",                       :default => false
    t.string   "reporter_name",             :default => ""
    t.string   "eliminator_name",           :default => ""
    t.string   "verifier_name",             :default => ""
    t.datetime "completed_at"
    t.datetime "credited_at"
    t.boolean  "is_credited"
    t.integer  "feed_type_cd"
    t.integer  "neighborhood_id"
    t.string   "status"
  end

  create_table "reports_users", :id => false, :force => true do |t|
    t.integer "report_id"
    t.integer "user_id"
  end

  create_table "team_memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "team_id"
    t.boolean  "verified"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "teams", :force => true do |t|
    t.string   "name"
    t.integer  "neighborhood_id"
    t.string   "profile_photo_file_name"
    t.string   "profile_photo_content_type"
    t.integer  "profile_photo_file_size"
    t.datetime "profile_photo_updated_at"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "password_digest"
    t.string   "auth_token"
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
    t.string   "email"
    t.string   "password_reset_token"
    t.datetime "password_reset_sent_at"
    t.string   "phone_number"
    t.integer  "points",                     :default => 0,                 :null => false
    t.integer  "house_id"
    t.string   "profile_photo_file_name"
    t.string   "profile_photo_content_type"
    t.integer  "profile_photo_file_size"
    t.datetime "profile_photo_updated_at"
    t.boolean  "is_verifier",                :default => false
    t.boolean  "is_fully_registered",        :default => false
    t.boolean  "is_health_agent",            :default => false
    t.string   "first_name",                 :default => ""
    t.string   "middle_name",                :default => ""
    t.string   "last_name",                  :default => ""
    t.string   "nickname",                   :default => ""
    t.string   "display",                    :default => "firstmiddlelast"
    t.string   "role",                       :default => "morador"
    t.integer  "total_points",               :default => 0
    t.boolean  "gender",                     :default => true
    t.boolean  "is_blocked",                 :default => false
    t.string   "carrier",                    :default => ""
    t.boolean  "prepaid"
    t.integer  "neighborhood_id"
  end

end
