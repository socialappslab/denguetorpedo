# == Schema Information
#
# Table name: notifications
#
#  id         :integer          not null, primary key
#  phone      :string(255)
#  text       :text
#  board      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  read       :boolean          default(FALSE)
#

require 'spec_helper'

describe Notification do
  pending "add some examples to (or delete) #{__FILE__}"
end
