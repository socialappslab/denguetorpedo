
Given /^(?:|I )have an account with the following:$/ do |fields|
  attributes = {}
  fields.rows_hash.each do |name, value|
    When %{I fill in "#{name}" with "#{value}"}
    attributes[name] = value;
  User.create!(attributes)
  end
end

And /^ I'm on the "(.*)" page/ do |page|
  pending("Need to implement")

end