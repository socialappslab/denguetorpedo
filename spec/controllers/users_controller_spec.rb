# encoding: utf-8
require 'spec_helper'

describe UsersController do
	render_views

	#-----------------------------------------------------------------------------

	context "Registering a user" do
		context "when user inputs valid information" do
			it "redirects them to their edit page" do
				visit root_path

				fill_in "user_email", 		 					 :with => "test@denguetorpedo.com"
				fill_in "user_first_name", 					 :with => "Test"
				fill_in "user_last_name",  					 :with => "Tester"
				fill_in "user_password", 						 :with => "abcdefg"
				fill_in "user_password_confirmation", :with => "abcdefg"
				click_button "Cadastre-se!"

				user = User.find_by_email("test@denguetorpedo.com")
				expect(current_path).to eq( edit_user_path(user) )
			end
		end
	end

	#-----------------------------------------------------------------------------

	context "Logging a user in" do
		let(:user) { FactoryGirl.create(:user) }

		before(:each) do
			visit root_path
		end

		it "displays appropriate error message for invalid input" do
			fill_in "email", :with => user.email
			fill_in "password", :with => ""
			click_button "Entrar"

			expect(page).to have_content("E-mail ou senha inválido")
			expect(page).not_to have_content("Invalid email")
		end

		it "doesn't display Signed in message" do
			fill_in "email", :with => user.email
			fill_in "password", :with => user.password
			click_button "Entrar"

			expect(page).not_to have_content("Signed in")
		end
	end

	#-----------------------------------------------------------------------------

	context "Logging a user out" do
		let(:user) { FactoryGirl.create(:user) }

		before(:each) do
			sign_in(user)
		end

		it "doesn't display Signed out message" do
			visit logout_path

			expect(page).not_to have_content("Signed out")
		end
	end

	#-----------------------------------------------------------------------------

	context "Editing a user" do
		let(:user) { FactoryGirl.create(:user) }

		before(:each) do
			sign_in(user)
		end

		context "when user inputs invalid information" do
			it "notifies the user of short phone number" do
				visit edit_user_path(user)
				fill_in "user_phone_number", :with => ""
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(page).to have_content("Número de celular invalido.  O formato correto é 0219xxxxxxxx")
			end

			it "notifies the user of missing carrier" do
				visit edit_user_path(user)
				fill_in "user_carrier", :with => ""
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(page).to have_content("Informe a sua operadora")
			end
		end

		context "when user inputs valid information" do
			it "updates the user's neighborhood" do
				# TODO: Pending until we introduce a second neighborhood
				pending

				expect(user.neighborhood_id).to eq(Neighborhood.first.id)

				visit edit_user_path(user)

				select Neighborhood.all[1].id, :from =>  "user_neighborhood_id"
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(user.reload.neighborhood_id).to eq(Neighborhood.all[1].id)
				expect(page).to have_content("Perfil atualizado com sucesso")
			end

			it "updates the user's house" do
				visit edit_user_path(user)

				fill_in "user_house_attributes_name", :with => "TEST"
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(user.reload.house.name).to eq("TEST")
				expect(page).to have_content("Perfil atualizado com sucesso")
			end

			it "updates the user's house location" do
				user.house.location_id = nil
				user.house.save(:validate => false)

				visit edit_user_path(user)
				fill_in "user_location_street_type", 	:with => "Rua"
				fill_in "user_location_street_name", 	:with => "Boca"
				fill_in "user_location_street_number", :with => "50"

				within "#house_configuration" do
					click_button "Confirmar"
				end

				expect(user.reload.house.location.street_type).to eq("Rua")
				expect(page).to have_content("Perfil atualizado com sucesso")
			end

			it "updates the user's house location" do
				visit edit_user_path(user)
				fill_in "user_location_street_type", 	:with => "Rua"
				fill_in "user_location_street_name", 	:with => "Boca"
				fill_in "user_location_street_number", :with => "50"

				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(user.reload.house.location.street_type).to eq("Rua")
				expect(page).to have_content("Perfil atualizado com sucesso")
			end
		end

		context "when editing house information" do
			it "notifies the user of missing house name" do
				visit edit_user_path(user)
				fill_in "user_house_attributes_name", :with => ""

				within "#house_configuration" do
					click_button "Confirmar"
				end

				expect(page).to have_content("Preencha o nome da casa")
			end

			it "notifies the user of a short house name" do
				visit edit_user_path(user)
				fill_in "user_house_attributes_name", :with => "A"

				within "#house_configuration" do
					click_button "Confirmar"
				end

				expect(page).to have_content("Insira um nome da casa válido")
			end

			it "notifies the user of missing house name" do
				visit edit_user_path(user)
				fill_in "user_house_attributes_name", :with => ""

				within "#house_configuration" do
					click_button "Confirmar"
				end

				expect(page).to have_content("Preencha o nome da casa")
			end

			it "creates a new instance if user chooses a new house" do
				visit edit_user_path(user)

				fill_in "user_house_attributes_name", :with => "TEST"
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(user.reload.house.name).to eq("TEST")
				expect(House.count).to eq(1)
				expect(page).to have_content("Perfil atualizado com sucesso")
			end

			context "when choosing a pre-existing house name" do
				let(:house) { FactoryGirl.create(:house, :name => "TEST HOUSE") }

				it "prevents user from setting a house's neighborhood" do
					pending "Need to get a second neighborhood"
					
					house.neighborhood_id = Neighborhood.all[1].id
					house.save(:validate => false)

					visit edit_user_path(user)
					select Neighborhood.first.name, :from => "user_neighborhood_id"

					fill_in "user_house_attributes_name", :with => house.name
					within "#house_configuration" do
						click_button "Confirmar"
					end

					within "#house_configuration" do
						click_button "Confirmar"
					end

					expect(house.reload.neighborhood_id).to eq(nil)
					expect(page).to have_content("Perfil atualizado com sucesso")
				end

				it "does not create a new house" do
					visit edit_user_path(user)

					fill_in "user_house_attributes_name", :with => house.name
					within "#house_configuration" do
						click_button "Confirmar"
					end

					# We expect only the user's house and the one they chose to exist.
					expect(House.count).to eq(2)
				end

				it "asks for confirmation" do
					visit edit_user_path(user)

					fill_in "user_house_attributes_name", :with => house.name
					within "#house_configuration" do
						click_button "Confirmar"
					end
					expect(page).to have_content("Uma casa com esse nome já existe. Você quer se juntar a essa casa? Se sim, clique confirmar.")
				end

				it "saves the profile upon confirmation" do
					visit edit_user_path(user)

					# puts "House.all: #{House.all.map(&:name)}"

					fill_in "user_house_attributes_name", :with => house.name
					within "#house_configuration" do
						click_button "Confirmar"
					end


					within "#house_configuration" do
						click_button "Confirmar"
					end

					expect(user.reload.house.name).to eq(house.name)

					# We expect only the user's house and the one they chose to exist.
					expect(House.count).to eq(2)
					expect(page).to have_content("Perfil atualizado com sucesso")
				end
			end
		end

	end


	#-----------------------------------------------------------------------------
end
