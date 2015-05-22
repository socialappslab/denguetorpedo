json.(comment, :id, :content, :likes_count)
json.timestamp timestamp_in_metadata(comment.created_at)

json.user do
  json.partial! "api/v0/users/user", user: comment.user
end
