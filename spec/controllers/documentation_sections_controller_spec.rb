require 'spec_helper'

describe DocumentationSectionsController do
  let(:user) { FactoryGirl.create(:coordinator, :neighborhood_id => Neighborhood.first.id) }

  describe "editing in Spanish" do
    before(:each) do
      cookies[:auth_token]        = user.auth_token
      cookies[:locale_preference] = "es"
    end

    it "does not affect title and content of Portueguse translation" do
      ds          = DocumentationSection.first
      old_title   = ds[:title]
      old_content = ds[:content]

      put :update, :id => ds.id, :documentation_section => {:title => "Changed Content", :content => "Spanish text"}

      expect(ds[:title]).to eq(old_title)
      expect(ds[:content]).to eq(old_content)
    end

    it "changes title and content of Portueguse translation" do
      ds = DocumentationSection.first

      put :update, :id => ds.id, :documentation_section => {:title => "Changed Content", :content => "Spanish text"}

      ds = ds.reload
      expect(ds.title).to           eq("Changed Content")
      expect(ds.content).to         eq("Spanish text")
      expect(ds[:title_in_es]).to   eq("Changed Content")
      expect(ds[:content_in_es]).to eq("Spanish text")
    end
  end

end
