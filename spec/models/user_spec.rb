# -*- encoding : utf-8 -*-

require "rails_helper"
require "cancan/matchers"

describe User do
	let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }

	before(:each) do
		I18n.default_locale = User::Locales::SPANISH
	end

	#-----------------------------------------------------------------------------

	it "validates presence of neighborhood" do
		I18n.locale = I18n.default_locale
		user.neighborhood_id = nil
		user.save
		expect(user.errors.full_messages).to include("Comunidad es obligatorio")
	end

	#-----------------------------------------------------------------------------

	describe "Validations" do

		describe "on Username" do
		it "disallows spaces" do
				user = FactoryGirl.build(:user, :username => "Dmitri S")
				user.save
				expect(user.errors.messages[:username]).to include( I18n.t("activerecord.errors.users.invalid_username") )
			end

			it "disallows @" do
				user = FactoryGirl.build(:user, :username => "@dmitri")
				user.save
				expect(user.errors.messages[:username]).to include( I18n.t("activerecord.errors.users.invalid_username") )
			end

			it "disallows ." do
				user = FactoryGirl.build(:user, :username => "dmitri.skj")
				user.save
				expect(user.errors.messages[:username]).to include(I18n.t("activerecord.errors.users.invalid_username"))
			end

			it "allows underscores" do
				user = FactoryGirl.build(:user, :username => "dmitri_skj")
				user.save
				expect(user.errors.messages[:username]).to eq(nil)
			end

			it "allows normal susernames" do
				user = FactoryGirl.build(:user, :username => "dmitri")
				user.save
				expect(user.errors.messages[:username]).to eq(nil)
			end
		end
	end

	#-----------------------------------------------------------------------------

	describe "abilities" do
    before(:each) do
      skip "Fix CanCan roles"
    end

		context "when user is a coordinator" do
			let(:user) { FactoryGirl.create(:coordinator, :neighborhood_id => Neighborhood.first.id) }
			it { is_expected.to be_able_to(:assign_roles, user)}
			it { is_expected.to be_able_to(:edit, user)}
		end

		context "when user is a resident" do
			it { is_expected.not_to be_able_to(:assign_roles, user)}
			it { is_expected.not_to be_able_to(:edit, user) }
		end
	end

	describe "when destroying a user" do
		let!(:notification) { FactoryGirl.create(:message_notification, :user_id => user.id, :notification_id => 1) }

		it "destroys all associated notifications" do
			expect {
				user.destroy
			}.to change(UserNotification, :count).by(-1)
		end

	end
end
