class EliminationTypesController < ApplicationController
	def create
	end

	def update
		@type = EliminationType.find(params[:id])
		@type.name = params[:name]

		respond_to do |format|
			if @type.save
				format.js
			else
			end
		end
	end
	def destroy
		@type = EliminationType.find(params[:id])
		@methods = @type.elimination_methods
		respond_to do |format|
			if @type.destroy
				format.js
			else
				format.json { render json: {message: "failure"}, status: 401}
			end
		end
	end
end
