# -*- encoding : utf-8 -*-
require "rails_helper"

describe "Reports", :type => :feature do
  let!(:neighborhood)     { FactoryGirl.create(:neighborhood) }
  let(:user) 						 { FactoryGirl.create(:user, :neighborhood_id => neighborhood.id) }
  let(:other_user)       { FactoryGirl.create(:user, :neighborhood_id => neighborhood.id) }
  let!(:elimination_type) { FactoryGirl.create(:breeding_site) }
  let(:location)         { FactoryGirl.create(:location, :neighborhood => neighborhood) }
  let(:team)             { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => neighborhood.id) }
  let(:base64_image)     { "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAbAA8DASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwBlt4f0yC0ls1t5PKkJ3gysSefWrkXhzTJPkWF0OOCJCcfnUkcqFjlgOauQzIrjkVCm0XyJ9DmY761Zs/a4uecbxVtb61XBN1H/AN9ivHRFHNOxkRW4J6VXKJx8if8AfIrR4eztclVdNj//2Q=="}
  let(:inspection_time)  { Time.parse("2015-01-01 10:00") }

  before(:each) do
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => user.id)
    FactoryGirl.create(:team_membership, :team_id => team.id, :user_id => other_user.id)

    I18n.default_locale = User::Locales::SPANISH
  end

  #-----------------------------------------------------------------------------

  describe "Visiting Reports page" do
    before(:each) do
      sign_in(user)

      6.times do |index|
        u = (index % 2 == 0 ? user : other_user)
        r = FactoryGirl.build(:report, :report => "Report with index #{index}", :reporter_id => u.id, :neighborhood_id => neighborhood.id, :created_at => inspection_time, :completed_at => inspection_time)
        if index == 0
          r.elimination_method_id = r.breeding_site.elimination_methods.first.id
          r.eliminated_at = inspection_time + 5.minutes
          r.after_photo = Rack::Test::UploadedFile.new('spec/support/foco_marcado.jpg', 'image/jpg')
        end

        r.save!
      end

      visit neighborhood_reports_path(user.neighborhood)
    end

    it "displays the description text" do
      expect(page).to have_content("Esta página muestra reportes de criaderos potenciales o positivos en la comunidad")
    end

    it "displays Call-To-Action button for un-eliminated reports" do
      expect( page.all(".eliminate-report-button").length ).to eq(5)
    end

    it "displays open reports first (ordered by last created)" do
      first_report = page.all(".report")[0]
      last_report  = page.all(".report")[-1]

      expect(first_report).to have_content("Report with index 0")
      expect(last_report).to have_content("Report with index 5")
    end
  end

  #---------------------------------------------------------------------------

end
