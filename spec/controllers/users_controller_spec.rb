# encoding: utf-8
require 'spec_helper'

describe UsersController do
	render_views

	#-----------------------------------------------------------------------------

	describe "Registering" do
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

	describe "Logging in" do
		let(:user) { FactoryGirl.create(:user) }
		
		it "displays appropriate error message for invalid input" do
			visit root_path

			fill_in "email", :with => user.email
			fill_in "password", :with => ""
			click_button "Entrar"

			expect(page).to have_content("E-mail ou senha inválido")
			expect(page).not_to have_content("Invalid email")
		end
	end

	#-----------------------------------------------------------------------------

	describe "Editing" do
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

			it "notifies the user of a short house name" do
				visit edit_user_path(user)
				fill_in "user_house_attributes_name", :with => "A"
				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(page).to have_content("Insira um nome da casa válido")
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

			it "sets the user's house neighborhood" do
				user.house.neighborhood_id = nil
				user.house.save(:validate => false)

				visit edit_user_path(user)
				select Neighborhood.first.name, :from => "user_neighborhood_id"

				within "#house_configuration" do
					click_button "Confirmar"
				end
				expect(user.reload.house.neighborhood.id).to eq(Neighborhood.first.id)
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


	end

	#-----------------------------------------------------------------------------
end
