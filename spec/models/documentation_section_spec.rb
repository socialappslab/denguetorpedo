# encoding: utf-8
require 'spec_helper'

describe DocumentationSection do
  it "validates title" do
    ds = DocumentationSection.create(:content => "Hello")
    expect(ds.errors.full_messages).to include("Título é obrigatório")
  end

  it "validates content" do
    ds = DocumentationSection.create(:title => "Hello")
    expect(ds.errors.full_messages).to include("Conteúdo é obrigatório")
  end
end
