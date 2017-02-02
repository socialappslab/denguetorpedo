json.posts @posts do |post|
  json.partial! "api/v0/posts/post", :post => post

  if params[:mobile].present?
    begin
      json.base64_user_photo Base64.encode64(open(post.user.profile_photo.url(:thumbnail)) { |io| io.read })
    rescue
    end
  end
end
