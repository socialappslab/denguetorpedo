# -*- encoding : utf-8 -*-

class Coordinator::NoticesController < Coordinator::BaseController
  #----------------------------------------------------------------------------
  # GET /coordinator/notices/new

  def new
    @notice = Notice.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @notice }
    end
  end

  #----------------------------------------------------------------------------
  # POST /notices

  def create
    @notice = Notice.new(params[:notice])
    @notice.neighborhood_id = params[:notice][:neighborhood_id]

    respond_to do |format|
      if @notice.save
        format.html { redirect_to coordinator_notice_path(@notice), notice: 'Notícia criada com sucesso.' }
        format.json { render json: @notice, status: :created, location: @notice }
      else
        format.html { render action: "coordinator/notices/new" }
        format.json { render json: @notice.errors, status: :unprocessable_entity }
      end
    end
  end

  #----------------------------------------------------------------------------
  # GET /notices/1/edit

  def edit
    @neighborhoods = Neighborhood.all.collect{ |neighborhood| [neighborhood.name, neighborhood.id]}
    @notice = Notice.find(params[:id])
  end

  #----------------------------------------------------------------------------
  # PUT /notices/1

  def update
    @notice = Notice.find(params[:id])

    respond_to do |format|
      if @notice.update_attributes(params[:notice])
        @notice.save
        format.html { redirect_to coordinator_notice_path(@notice), notice: 'Notícia atualizado com sucesso.' }
        format.json { head :no_content }
      else
        format.html { render action: "coordinator/notices/edit" }
        format.json { render json: @notice.errors, status: :unprocessable_entity }
      end
    end
  end


  #----------------------------------------------------------------------------
  # DELETE /notices/1

  def destroy
    @notice = Notice.find(params[:id])
    @notice.destroy

    respond_to do |format|
      format.html { redirect_to root_url }
      format.json { head :no_content }
    end
  end

  #----------------------------------------------------------------------------
  # GET /notices/1

  def show
    @notice = Notice.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @notice }
    end
  end

  #----------------------------------------------------------------------------

end
