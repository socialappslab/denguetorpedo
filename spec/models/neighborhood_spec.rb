# == Schema Information
#
# Table name: neighborhoods
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  coordinator_id :integer
#

require 'spec_helper'

describe Neighborhood do
  pending "add some examples to (or delete) #{__FILE__}"
end
