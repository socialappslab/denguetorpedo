# encoding: UTF-8

class DocumentationSectionsController < ApplicationController
  #-----------------------------------------------------------------------------

  before_filter :require_login
  before_filter :ensure_admin
  before_filter :identify_section

  #-----------------------------------------------------------------------------
  # GET /documentation_sections/1/edit

  def edit
  end

  #-----------------------------------------------------------------------------
  # PUT /documentation_sections/1

  def update
    @section.editor_id = @current_user.id
    
    if @section.update_attributes(params[:documentation_section])
      flash[:notice] = "Successfully updated"
      redirect_to howto_path and return
    else
      render "edit" and return
    end
  end

  #-----------------------------------------------------------------------------

  private

  #-----------------------------------------------------------------------------

  def ensure_admin
    return (@current_user.role == "admin")
  end

  def identify_section
    @section = DocumentationSection.find(params[:id])
  end

  #-----------------------------------------------------------------------------
end
