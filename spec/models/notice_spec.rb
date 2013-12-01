# == Schema Information
#
# Table name: notices
#
#  id                 :integer          not null, primary key
#  title              :string(255)      default("")
#  description        :text             default("")
#  location           :string(255)      default("")
#  date               :datetime
#  neighborhood_id    :integer
#  user_id            :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  photo_file_name    :string(255)
#  photo_content_type :string(255)
#  photo_file_size    :integer
#  photo_updated_at   :datetime
#  summary            :text             default("")
#  institution_name   :string(255)
#

require 'spec_helper'

describe Notice do
  pending "add some examples to (or delete) #{__FILE__}"
end
