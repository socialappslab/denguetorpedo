class DocumentationSection < ActiveRecord::Base
  attr_accessible :title, :content

  validates :title, :presence => true
  validates :content, :presence => true

  #----------------------------------------------------------------------------

  belongs_to :editor, :class_name => "User"

  #----------------------------------------------------------------------------

  def html_id_tag
    self.title.downcase.gsub(" ", "_")
  end

  #----------------------------------------------------------------------------
end
