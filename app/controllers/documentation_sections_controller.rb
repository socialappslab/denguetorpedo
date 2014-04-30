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
      flash[:notice] = "A seção foi atualizada com sucesso"
      redirect_to howto_path and return
    else
      render "edit" and return
    end
  end

  #-----------------------------------------------------------------------------

  private

  #-----------------------------------------------------------------------------

  def ensure_admin
    unless ["admin", "coordenador"].include?(@current_user.role)
      redirect_to howto_path, :alert => "Você não pode acessar esse conteúdo" and return
    end
  end

  def identify_section
    @section = DocumentationSection.find(params[:id])
  end

  #-----------------------------------------------------------------------------
end
