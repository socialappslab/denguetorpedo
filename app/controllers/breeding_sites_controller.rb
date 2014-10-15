class BreedingSitesController < ApplicationController
	before_filter :ensure_proper_permissions

	#-----------------------------------------------------------------------------
	# GET /elimination_types

	def index
		@types = BreedingSite.includes(:elimination_methods)

		if I18n.locale == User::Locales::SPANISH
			@types = @types.order("description_in_es ASC")
		else
			@types = @types.order("description_in_pt ASC")
		end
	end

	#-----------------------------------------------------------------------------
	# GET /elimination_types/new

	def new
		@type = BreedingSite.new
	end

	#-----------------------------------------------------------------------------
	# GET /elimination_types/1/edit

	def edit
		@type = BreedingSite.find( params[:id] )
	end

	#-----------------------------------------------------------------------------
	# POST /breeding_sites

	def create
		@type = BreedingSite.new( params[:breeding_site] )

		if @type.save
			flash[:notice] = "You successfully created a breeding site"
			redirect_to breeding_sites_path and return
		else
			render "new" and return
		end
	end

	#-----------------------------------------------------------------------------
	# PUT /breeding_sites/1

	def update
		@type = BreedingSite.find( params[:id] )

		if @type.update_attributes( params[:breeding_site] )
			flash[:notice] = "You successfully updated a breeding site"
			redirect_to breeding_sites_path and return
		else
			render "edit" and return
		end
	end

	#-----------------------------------------------------------------------------
	# DELETE /elimination_types

	def destroy
		@type = BreedingSite.find( params[:id] )

		if @type.destroy
			flash[:notice] = "You successfully destroyed a breeding site type."
			redirect_to breeding_sites_path and return
		else
			flash[:alert] = I18n.t("views.application.error")
			redirect_to breeding_sites_path and return
		end
	end

	#-----------------------------------------------------------------------------

end
