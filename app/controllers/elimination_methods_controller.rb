class EliminationMethodsController < ApplicationController
	def create
		@method = EliminationMethod.new(method: params[:name], points: params[:points])
		@type = EliminationType.find(params[:type_id])
		@current_id = params[:current_id]
		@method.elimination_type = @type
		respond_to do |format|
			if @method.save
				format.js
			else
			end
		end
	end

	def update
		@method = EliminationMethod.find(params[:id])
		@method.method = params[:name]
		@method.points = params[:points]
		respond_to do |format|
			if @method.save
				format.js
			else
			end
		end
	end
	def destroy
		@method = EliminationMethod.find(params[:id])

		respond_to do |format|
			if @method.destroy

				format.js
			else
				format.json { render json: {message: "failure"}, status: 401}
			end
		end
	end
end
