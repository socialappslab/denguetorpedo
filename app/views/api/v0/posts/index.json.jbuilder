json.posts @posts do |post|
  json.(post, :id, :content, :likes_count)

  # Paths
  json.image_path  post.photo.url(:large)
  json.delete_path api_v0_post_path(post)
  json.like_path   like_api_v0_post_path(post)

  json.timestamp   timestamp_in_metadata(post.created_at)


  json.user do
    json.partial! 'api/v0/users/user', user: post.user
  end

  json.comments post.comments.order("created_at ASC") do |comment|
    json.(comment, :id, :content, :created_at)
    json.formatted_created_at comment.formatted_created_at
    json.user do
      json.partial! "api/v0/users/user", user: comment.user
    end

    json.post_path comment_post_path(comment)
    json.timestamp timestamp_in_metadata(comment.created_at)

  end
end
