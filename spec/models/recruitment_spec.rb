# == Schema Information
#
# Table name: recruitments
#
#  id           :integer          not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  recruiter_id :integer
#  recruitee_id :integer
#

require 'spec_helper'

describe Recruitment do
  pending "add some examples to (or delete) #{__FILE__}"
end
