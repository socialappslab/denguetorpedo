# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :manual_instruction do
    title "MyString"
    description "MyText"
    user_id 1
    created_at "2014-03-14 10:30:52"
    updated_at "2014-03-14 10:30:52"
  end
end
