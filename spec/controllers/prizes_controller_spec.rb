# -*- encoding : utf-8 -*-
require 'spec_helper'

describe PrizesController do
  let(:team) { FactoryGirl.create(:team, :name => "Test Team", :neighborhood_id => Neighborhood.first.id)}
  let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id)}

  # This should return the minimal set of attributes required to create a valid
  # Prize. As you add validations to Prize, be sure to
  # update the return value of this method accordingly.

  before(:each) do
    @user     = FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id)
    controller.stub(:require_login).and_return(true)
  end

  def valid_attributes
    { :cost => 30, :neighborhood_id => Neighborhood.first.id, :description => "Description", :prize_name => "Prize", :stock => 5, :user_id => @user.id, :team_id => team.id }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PrizesController. Be sure to keep this updated too.
  def valid_session
    {}
  end

  describe "GET index" do
    before(:each) do
      @prize = Prize.create! valid_attributes
    end
    it "should be successful" do
      get :index, {}, valid_session
      response.should be_success
    end

    it "assigns all prizes as @prizes" do
      get :index, {}, valid_session
      assigns(:prizes).should eq([@prize])
    end
  end

  describe "GET show" do
    before(:each) do
      @prize = FactoryGirl.create(:prize, valid_attributes)
    end

    it "should be successful" do
      get :show, id: @prize.id
      response.should be_success
    end
    it "assigns the requested prize as @prize" do
      get :show, id: @prize.id
      assigns(:prize).should eq(@prize)
    end
  end

  describe "GET new" do
    it "assigns a new prize as @prize" do
      get :new
      assigns(:prize).should be_a_new(Prize)
    end
  end

  #----------------------------------------------------------------------------

  describe "GET edit" do
    it "assigns the requested prize as @prize" do
      prize = FactoryGirl.create(:prize, valid_attributes)
      get :edit, {:id => prize.id}, valid_session
      assigns(:prize).should eq(prize)
    end
  end

  #----------------------------------------------------------------------------

  describe "when creating a prize" do
    let(:params) {
      {
        :cost => 30,
        :description => "Description",
        :prize_name => "Prize",
        :stock => 5,
        :user_id => user.id,
        :team_id => team.id,
        :neighborhood_id => Neighborhood.first.id
      }
    }

    describe "with valid params" do
      it "creates a new Prize" do
        expect {
          post :create, {:prize => valid_attributes}, valid_session
        }.to change(Prize, :count).by(1)
      end

      it "assigns a team id" do
        post :create, :prize => params
        prize = Prize.last
        expect(prize.team_id).to eq(team.id)
      end

      it "assigns a neighborhood to a prize if one is specified" do
        attrs = valid_attributes.merge(:neighborhood_id => Neighborhood.first.id)
        post :create, :prize => attrs
        expect(Prize.last.neighborhood_id).to eq(Neighborhood.first.id)
      end

      it "assigns a newly created prize as @prize" do
        post :create, {:prize => valid_attributes}, valid_session
        assigns(:prize).should be_a(Prize)
        assigns(:prize).should be_persisted
      end

      it "redirects to the created prize" do
        post :create, {:prize => valid_attributes}, valid_session
        response.should redirect_to(Prize.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved prize as @prize" do
        # Trigger the behavior that occurs when invalid params are submitted
        Prize.any_instance.stub(:save).and_return(false)
        post :create, {:prize => {}}, valid_session
        assigns(:prize).should be_a_new(Prize)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Prize.any_instance.stub(:save).and_return(false)
        post :create, {:prize => {}}, valid_session
        response.should render_template("new")
      end
    end
  end

  #----------------------------------------------------------------------------

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested prize" do
        prize = Prize.create! valid_attributes

        # Assuming there are no other prizes in the database, this
        # specifies that the Prize created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Prize.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => prize.to_param, :prize => {'these' => 'params'}}, valid_session
      end

      it "assigns the requested prize as @prize" do
        prize = Prize.create! valid_attributes
        put :update, {:id => prize.to_param, :prize => valid_attributes}, valid_session
        assigns(:prize).should eq(prize)
      end

      it "redirects to the prize" do
        prize = FactoryGirl.create(:prize, valid_attributes)
        put :update, {:id => prize.to_param, :prize => valid_attributes}, valid_session
        response.should redirect_to(prize)
      end
    end

    describe "with invalid params" do
      it "assigns the prize as @prize" do
        prize = FactoryGirl.create(:prize, valid_attributes)
        # Trigger the behavior that occurs when invalid params are submitted
        Prize.any_instance.stub(:save).and_return(false)
        put :update, {:id => prize.to_param, :prize => {}}, valid_session
        assigns(:prize).should eq(prize)
      end

      it "re-renders the 'edit' template" do
        prize = FactoryGirl.create(:prize, valid_attributes)
        # Trigger the behavior that occurs when invalid params are submitted
        Prize.any_instance.stub(:save).and_return(false)
        put :update, {:id => prize.to_param, :prize => {}}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @prize = FactoryGirl.create(:prize, valid_attributes)
    end

    it "destroys the requested prize" do
      expect {
        delete :destroy, {:id => @prize.id}, valid_session
      }.to change(Prize, :count).by(-1)
    end

    it "redirects to the prizes list" do
      delete :destroy, {:id => @prize.id}, valid_session
      response.should redirect_to(prizes_url)
    end
  end

end
