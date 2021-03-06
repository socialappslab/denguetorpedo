# -*- encoding : utf-8 -*-
# # encoding: utf-8
# require "rails_helper"
#
# describe "How To", :type => :feature do
#   let(:section) { DocumentationSection.first }
#   let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
#
#   before(:each) do
#     I18n.default_locale = User::Locales::PORTUGUESE
#   end
#
#   it "displays seeded data" do
#     visit howto_path
#     expect(page).to have_content("Como completar sua conta")
#     expect(page).to have_content("O que é um foco?")
#   end
#
#   it "doesn't display an edit link" do
#     visit howto_path
#     expect(page).not_to have_content("Edit")
#   end
#
#   it "doesn't allow editing of sections for visitors" do
#     visit edit_documentation_section_path(section)
#     expect(page).to have_content("Cadastre-se para")
#   end
#
#   it "doesn't allow editing of sections for logged-in users" do
#     sign_in(user)
#     visit edit_documentation_section_path(section)
#     expect(page).to have_content( I18n.t("views.application.permission_required") )
#   end
#
#   context "as a coordinator" do
#     let(:admin)   { FactoryGirl.create(:user, :role => User::Types::COORDINATOR, :neighborhood_id => Neighborhood.first.id) }
#
#     before(:each) do
#       sign_in(admin)
#     end
#
#     it "displays the edit link" do
#       visit howto_path
#       expect(page).to have_content("Edit")
#       expect(first("##{section.html_id_tag} a")[:href]).to eq(edit_documentation_section_path(section))
#     end
#
#     it "allows editing of sections" do
#       visit howto_path
#       within "##{section.html_id_tag}" do
#         click_link "Edit"
#       end
#
#       expect(page).to have_content("Título")
#       expect(page).to have_content("Conteúdo")
#     end
#
#     it "displays that no one has edited the section before" do
#       visit edit_documentation_section_path(section)
#       expect(page).to have_content("Essa seção ainda não foi editada")
#     end
#
#     it "allows title change" do
#       visit edit_documentation_section_path(section)
#       fill_in "documentation_section_title", :with => "TEST"
#       click_button "Enviar"
#       expect(page).to have_content("TEST")
#       expect(page).to have_content("Seção foi atualizada com sucesso")
#     end
#
#     it "allows content change" do
#       visit edit_documentation_section_path(section)
#       fill_in "documentation_section_content", :with => "TEST"
#       click_button "Enviar"
#       expect(page).to have_content("TEST")
#       expect(page).to have_content("Seção foi atualizada com sucesso")
#     end
#
#     it "requires title" do
#       visit edit_documentation_section_path(section)
#       fill_in "documentation_section_title", :with => ""
#       click_button "Enviar"
#       expect(page).to have_content("Título em Português")
#     end
#
#     it "requires content" do
#       visit edit_documentation_section_path(section)
#       fill_in "documentation_section_content", :with => ""
#       click_button "Enviar"
#       expect(page).to have_content("Conteúdo em Português é obrigatório")
#     end
#   end
#
#   #---------------------------------------------------------------------------
#
# end
