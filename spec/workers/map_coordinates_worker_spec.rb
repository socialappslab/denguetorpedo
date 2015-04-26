# -*- encoding : utf-8 -*-
# require "spec_helper"
#
# describe MapCoordinatesWorker do
#   let(:location) { FactoryGirl.create(:location) }
#
#   it "fetches map coordinates for a valid address" do
#     expect(location.latitude).to eq(nil)
#     expect(location.longitude).to eq(nil)
#
#     MapCoordinatesWorker.perform_async(location.id)
#
#     location.reload
#     expect(location.latitude).to  eq(680291.2151545063)
#     expect(location.longitude).to eq(7471401.29586681)
#   end
#
# end
