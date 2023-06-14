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

ActiveRecord::Schema[7.0].define(version: 2023_06_14_133703) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "movies", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "queries", force: :cascade do |t|
    t.string "medium"
    t.integer "time"
    t.string "audience"
    t.string "genre"
    t.integer "happiness"
    t.integer "intensity"
    t.integer "novelty"
    t.string "recent_movie1"
    t.string "recent_movie2"
    t.string "recent_movie3"
    t.text "other"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "year_before"
    t.integer "year_after"
    t.integer "year_option"
    t.bigint "user_id", null: false
    t.string "streaming_platform"
    t.integer "desired_happiness"
    t.index ["user_id"], name: "index_queries_on_user_id"
  end

  create_table "recommendation_watch_lists", force: :cascade do |t|
    t.bigint "recommendation_id", null: false
    t.bigint "watch_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recommendation_id"], name: "index_recommendation_watch_lists_on_recommendation_id"
    t.index ["watch_list_id"], name: "index_recommendation_watch_lists_on_watch_list_id"
  end

  create_table "recommendations", force: :cascade do |t|
    t.string "movie_name"
    t.bigint "query_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "imdbID"
    t.string "genre"
    t.string "rating"
    t.string "image"
    t.string "awards"
    t.string "runtime"
    t.text "synopsis"
    t.string "director"
    t.string "writer"
    t.string "actors"
    t.string "rotten_score"
    t.string "imdb_score"
    t.string "trailer_link"
    t.string "year"
    t.bigint "watch_list_id"
    t.index ["query_id"], name: "index_recommendations_on_query_id"
    t.index ["user_id"], name: "index_recommendations_on_user_id"
    t.index ["watch_list_id"], name: "index_recommendations_on_watch_list_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "watch_lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_watch_lists_on_user_id"
  end

  add_foreign_key "queries", "users"
  add_foreign_key "recommendation_watch_lists", "recommendations"
  add_foreign_key "recommendation_watch_lists", "watch_lists"
  add_foreign_key "recommendations", "queries"
  add_foreign_key "recommendations", "users"
  add_foreign_key "recommendations", "watch_lists"
  add_foreign_key "watch_lists", "users"
end
