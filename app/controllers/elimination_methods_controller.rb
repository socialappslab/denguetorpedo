class EliminationMethodsController < ApplicationController
  before_filter :ensure_proper_permissions

  #----------------------------------------------------------------------------
  # GET /elimination_methods/new

  def new
    @type   = BreedingSite.find( params[:breeding_site_id] )
    @method = EliminationMethod.new
  end

  #----------------------------------------------------------------------------
  # GET /elimination_methods/:id/edit

  def edit
    @type   = BreedingSite.find( params[:breeding_site_id] )
    @method = EliminationMethod.find( params[:id] )
  end

  #----------------------------------------------------------------------------
  # POST /elimination_methods/:id

  def create
    @type   = BreedingSite.find( params[:breeding_site_id] )
    @method = EliminationMethod.new( params[:elimination_method] )

    @method.breeding_site_id = @type.id

    if @method.save
      flash[:notice] = "You've successfully created a new elimination type."
      redirect_to breeding_sites_path and return
    else
      render "new" and return
    end
  end

  #----------------------------------------------------------------------------
  # PUT /elimination_methods/:id

	def update
		@type   = BreedingSite.find( params[:breeding_site_id] )
    @method = EliminationMethod.find( params[:id] )

		if @method.update_attributes(params[:elimination_method])
      flash[:notice] = "You've successfully created a new elimination type."
      redirect_to breeding_sites_path and return
    else
      render "edit" and return
    end
	end

  #----------------------------------------------------------------------------
  # DELETE /elimination_methods/:id

	def destroy
		@method = EliminationMethod.find( params[:id] )

    if @method.destroy
      flash[:notice] = "You successfully destroyed an elimination type."
      redirect_to breeding_sites_path and return
    else
      flash[:alert] = I18n.t("views.application.error")
      redirect_to breeding_sites_path and return
    end
	end

  #----------------------------------------------------------------------------




end
