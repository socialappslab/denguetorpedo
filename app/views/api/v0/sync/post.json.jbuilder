json.post do
  json.partial! "api/v0/posts/post", :post => @post
end

json.last_sync_seq @last_seq
json.last_synced_at @last_synced_at
