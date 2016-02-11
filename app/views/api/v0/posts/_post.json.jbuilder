json.(post, :id, :content, :likes_count)

json.path post_path(post)

if post.photo_file_name.present?
  json.photo     post.photo.url(:large)
else
  json.photo nil
end

json.timestamp timestamp_in_metadata(post.created_at)

json.liked @user_post_likes && @user_post_likes.include?(post.id)

#-------------
# Associations
#-------------
json.user do
  json.partial! 'api/v0/users/user', user: post.user
end

json.comments post.comments.order("created_at ASC") do |comment|
  json.partial! "api/v0/comments/comment", comment: comment
end

#--------
# Actions
#--------
json.actions do
  json.delete api_v0_post_path(post)
  json.like   like_api_v0_post_path(post)
  json.create_comment comment_post_path(post)
end
