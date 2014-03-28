class ManualInstructionsController < ApplicationController
  # GET /manual_instructions
  # GET /manual_instructions.json
  def index
    @manual_instructions = ManualInstruction.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @manual_instructions }
    end
  end

  # GET /manual_instructions/new
  # GET /manual_instructions/new.json
  def new
    @manual_instruction = ManualInstruction.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @manual_instruction }
    end
  end

  # GET /manual_instructions/1/edit
  def edit
    @manual_instruction = ManualInstruction.find(params[:id])
  end

  # POST /manual_instructions
  # POST /manual_instructions.json
  def create
    @manual_instruction = ManualInstruction.new(params[:manual_instruction])

    respond_to do |format|
      if @manual_instruction.save
        format.html { redirect_to @manual_instruction, notice: 'Manual instruction was successfully created.' }
        format.json { render json: @manual_instruction, status: :created, location: @manual_instruction }
      else
        format.html { render action: "new" }
        format.json { render json: @manual_instruction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /manual_instructions/1
  # PUT /manual_instructions/1.json
  def update
    @manual_instruction = ManualInstruction.find(params[:id])
    redirect_to '/howto' and return
    respond_to do |format|
      if @manual_instruction.update_attributes(params[:manual_instruction])
        format.html { redirect_to @manual_instruction, notice: 'Manual instruction was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @manual_instruction.errors, status: :unprocessable_entity }
      end
    end

  end

  # DELETE /manual_instructions/1
  # DELETE /manual_instructions/1.json
  def destroy
    @manual_instruction = ManualInstruction.find(params[:id])
    @manual_instruction.destroy

    respond_to do |format|
      format.html { redirect_to manual_instructions_url }
      format.json { head :no_content }
    end
  end
end
