# -*- encoding : utf-8 -*-
require "rails_helper"

describe DocumentationSectionsController do
  before(:each) do
    skip
  end
  let(:user) { FactoryGirl.create(:coordinator, :neighborhood_id => Neighborhood.first.id) }

  #----------------------------------------------------------------------------

  describe "Editing a Section" do
    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "changes title and content" do
      ds = DocumentationSection.first

      put :update, :id => ds.id, :documentation_section => {:title => "New PT Title", :content => "New PT Content", :title_in_es => "New Spanish Title", :content_in_es => "New Spanish Content"}

      ds = ds.reload
      expect(ds[:title]).to eq("New PT Title")
      expect(ds[:content]).to eq("New PT Content")
      expect(ds[:title_in_es]).to eq("New Spanish Title")
      expect(ds[:content_in_es]).to eq("New Spanish Content")
    end
  end

  #----------------------------------------------------------------------------

  describe "Creating a Section" do
    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "avoids creating a section if fields are empty" do
      expect {
        post :create, :documentation_section => {}
      }.not_to change(DocumentationSection, :count)
    end

    it "creates a new section" do
      expect {
        post :create, :documentation_section => {:title => "Test", :title_in_es => "Test", :content => "Test", :content_in_es => "Test"}
      }.to change(DocumentationSection, :count).by(1)
    end

    it "correctly sets instance attributes" do
      post :create, :documentation_section => {:title => "Test in PT", :title_in_es => "Test in ES", :content => "Content in PT", :content_in_es => "Content in ES"}

      ds = DocumentationSection.last
      expect(ds[:title]).to eq("Test in PT")
      expect(ds[:title_in_es]).to eq("Test in ES")
      expect(ds[:content]).to eq("Content in PT")
      expect(ds[:content_in_es]).to eq("Content in ES")
    end


    it "sets correct order id" do
      last_order_id = DocumentationSection.order("order_id DESC").select(:order_id).first.order_id

      post :create, :documentation_section => {:title => "Test in PT", :title_in_es => "Test in ES", :content => "Content in PT", :content_in_es => "Content in ES"}

      ds = DocumentationSection.last
      expect(ds.order_id).to eq(last_order_id + 1)
    end
  end

  #----------------------------------------------------------------------------


end
