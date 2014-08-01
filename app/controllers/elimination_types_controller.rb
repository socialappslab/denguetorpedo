class EliminationTypesController < ApplicationController

	#-----------------------------------------------------------------------------

	def create
		@type = BreedingSite.new(:name => params[:name])

		respond_to do |format|
			if @type.save
				format.js
			end
		end
	end

	#-----------------------------------------------------------------------------

	def update
		@type = BreedingSite.find( params[:id] )

		if I18n.locale == :es
			@type.description_in_es = params[:description]
		else
			@type.description_in_pt = params[:description]
		end

		respond_to do |format|
			if @type.save
				format.js
			else
			end
		end
	end

	#-----------------------------------------------------------------------------

	def show
		@type = BreedingSite.find( params[:id] )
		respond_to do |format|
			format.js
		end
	end

	#-----------------------------------------------------------------------------

	def destroy
		@type = BreedingSite.find( params[:id] )
		respond_to do |format|
			if @type.destroy
				format.js
			else
				format.json { render json: {message: "failure"}, status: 401}
			end
		end
	end

	#-----------------------------------------------------------------------------

end
