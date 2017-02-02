json.visit do
  json.partial! "api/v0/visits/visit", :visit => @visit
end
