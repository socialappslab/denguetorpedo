json.(comment, :id, :content, :likes_count)
json.timestamp timestamp_in_metadata(comment.created_at)
json.liked @user_comment_likes.include?(comment.id)

json.user do
  json.partial! "api/v0/users/user", user: comment.user
end
