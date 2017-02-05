json.posts @posts do |post|
  json.partial! "api/v0/posts/post", :post => post

  if params[:mobile].present?
    begin
      json.base64_user_photo Base64.encode64(open(post.user.profile_photo.url(:thumbnail)) { |io| io.read })
    rescue StandardError => e
      puts "\n\n\n\n[ERROR in posts.index.json.jbuilder] e = #{e.inspect}]\n\n\n\n"
    end
  end
end
