# -*- encoding : utf-8 -*-

class DocumentationSectionsController < ApplicationController
  #-----------------------------------------------------------------------------

  before_filter :require_login
  before_filter :ensure_coordinator
  before_filter :identify_section, :only => [:edit, :update, :destroy]

  #-----------------------------------------------------------------------------
  # GET /documentation_sections/1/edit

  def edit
  end

  #-----------------------------------------------------------------------------
  # GET /documentation_sections/1/new

  def new
    @section = DocumentationSection.new
  end

  #-----------------------------------------------------------------------------
  # POST /documentation_sections/1

  def create
    @section = DocumentationSection.new(params[:documentation_section])

    # Let's calculate the order id of the new section.
    last_order_id     = DocumentationSection.order("order_id DESC").select(:order_id).first.order_id
    @section.order_id = last_order_id + 1

    # Let's set the editor to be the current user.
    @section.editor_id = @current_user.id

    if @section.save
      flash[:notice] = I18n.t("views.documentation_sections.create.success")
      redirect_to howto_path and return
    else
      render "new" and return
    end

  end

  #-----------------------------------------------------------------------------
  # PUT /documentation_sections/1

  def update
    @section.editor_id = @current_user.id

    if @section.update_attributes(params[:documentation_section])
      flash[:notice] = I18n.t("views.documentation_sections.update.success")
      redirect_to howto_path and return
    else
      render "edit" and return
    end
  end

  #-----------------------------------------------------------------------------

  private

  #-----------------------------------------------------------------------------

  def ensure_coordinator
    unless @current_user.coordinator?
      redirect_to howto_path, :alert => I18n.t("views.application.permission_required") and return
    end
  end

  def identify_section
    @section = DocumentationSection.find(params[:id])
  end

  #-----------------------------------------------------------------------------
end
