class EliminationMethodsController < ApplicationController
	def create
	end

	def update
		@method = EliminationMethod.find(params[:id])
		@method.method = params[:name]
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
