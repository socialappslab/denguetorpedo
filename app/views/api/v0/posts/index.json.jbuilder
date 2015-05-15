json.posts @posts do |post|
  json.(post, :id, :content, :likes_count)
  json.photo     post.photo.url(:large)
  json.timestamp timestamp_in_metadata(post.created_at)

  #-------------
  # Associations
  #-------------
  json.user do
    json.partial! 'api/v0/users/user', user: post.user
  end

  json.comments post.comments.order("created_at ASC") do |comment|
    json.(comment, :id, :content)
    json.timestamp timestamp_in_metadata(comment.created_at)

    json.user do
      json.partial! "api/v0/users/user", user: comment.user
    end
  end

  #--------
  # Actions
  #--------
  json.actions do
    json.delete api_v0_post_path(post)
    json.like   like_api_v0_post_path(post)
    json.create_comment comment_post_path(post)
  end
end
