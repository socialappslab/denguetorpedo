# -*- encoding : utf-8 -*-
require "rails_helper"

describe DocumentationSection do
  before(:each) do
    I18n.locale = :pt
  end

  it "validates title" do
    ds = DocumentationSection.create(:content => "Hello")
    expect(ds.errors.full_messages).to include("Título em Português é obrigatório")
  end

  it "validates content" do
    ds = DocumentationSection.create(:title => "Hello")
    expect(ds.errors.full_messages).to include("Conteúdo em Português é obrigatório")
  end
end
