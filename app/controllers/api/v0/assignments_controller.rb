class API::V0::AssignmentsController < API::V0::BaseController
    skip_before_action :authenticate_user_via_device_token, :only => [:destroy, :update]
    before_action :current_user, :only => [:update, :destroy]

    def index
        @assignments = Assignment.all
        render json: @assignments.to_json, status: 200
    end

    def create
        @assignment = Assignment.new(params[:assignment])
        if @assignment.save
            render json: @assignment.to_json, status: 200
        else
            raise API::V0::Error.new(@assignment.errors.full_messages[0], 422)
        end
    end

    def update
        @assignment = Assignment.find_by(id: params[:id])
        if @assignment.update_attributes(params[:assignment])
            render json: @assignment.to_json, status: 200
        else
            raise API::V0::Error.new(@assignment.errors.full_messages[0], 422)
        end
    end

    def destroy
        @assignment = Assignment.find_by(id: params[:id])
        if @assignment.destroy
            render json: @assignment.to_json, status: 200
        else
            raise API::V0::Error.new(@assignment.errors.full_messages[0], 422)
        end
    end
end
