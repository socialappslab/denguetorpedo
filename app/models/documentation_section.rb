class DocumentationSection < ActiveRecord::Base
  attr_accessible :title, :content, :title_in_es, :content_in_es

  validates :title, :presence => true
  validates :title_in_es, :presence => true
  validates :content, :presence => true
  validates :content_in_es, :presence => true

  #----------------------------------------------------------------------------

  belongs_to :editor, :class_name => "User"

  #----------------------------------------------------------------------------

  def html_id_tag
    self.title.downcase.gsub(" ", "_")
  end

  #----------------------------------------------------------------------------

  def title
    if I18n.locale == :es
      return self[:title_in_es]
    else
      return self[:title]
    end
  end

  #----------------------------------------------------------------------------

  def content
    if I18n.locale == :es
      return self[:content_in_es]
    else
      return self[:content]
    end
  end

  #----------------------------------------------------------------------------

end
