# -*- encoding : utf-8 -*-
require "rails_helper"

describe Location do

  it 'creates location from a generic address string' do
    expect {
      l = Location.create(address: "Rua Tatajuba 50", :neighborhood_id => 1)
    }.to change(Location, :count).by(1)
  end

  describe "green?" do
    let(:location) { build_stubbed(:location) }

    it "returns false for location with no visits" do
      expect(location.green?).to eq(false)
    end

    it "returns false for locations with 1 visit" do
      add_visit_to_location(location, Inspection::Types::NEGATIVE)
      expect(location.green?).to eq(false)
    end

    it "returns false for locations with [N, N] (less than 2 months) visits" do
      add_visit_to_location(location, Inspection::Types::NEGATIVE)
      add_visit_to_location(location, Inspection::Types::NEGATIVE)
      expect(location.green?).to eq(false)
    end

    it "returns false for locations with [N, P, N] (more than 2 months) visits" do
      add_visit_to_location(location, Inspection::Types::NEGATIVE, Time.now)
      add_visit_to_location(location, Inspection::Types::POTENTIAL, Time.now - 1.month)
      add_visit_to_location(location, Inspection::Types::NEGATIVE, Time.now - 3.months)
      expect(location.green?).to eq(false)
    end

    it "returns true for locations with [N, N] (more than 2 months) visits" do
      add_visit_to_location(location, Inspection::Types::NEGATIVE, Time.now)
      add_visit_to_location(location, Inspection::Types::NEGATIVE, Time.now - 3.months)
      expect(location.green?).to eq(true)
    end

    it "returns true for locations with [N, N, N] where the span is 2 months" do
      add_visit_to_location(location, Inspection::Types::NEGATIVE, Time.now)
      add_visit_to_location(location, Inspection::Types::NEGATIVE, Time.now - 1.months)
      add_visit_to_location(location, Inspection::Types::NEGATIVE, Time.now - 5.months)
      expect(location.green?).to eq(true)
    end

    it "returns true for locations with [N, N, N, P] where the span is 2 months" do
      add_visit_to_location(location, Inspection::Types::NEGATIVE, Time.now)
      add_visit_to_location(location, Inspection::Types::NEGATIVE, Time.now - 1.months)
      add_visit_to_location(location, Inspection::Types::NEGATIVE, Time.now - 5.months)
      add_visit_to_location(location, Inspection::Types::POTENTIAL, Time.now - 10.months)
      expect(location.green?).to eq(true)
    end

  end
end
