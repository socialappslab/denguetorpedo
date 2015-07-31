# -*- encoding : utf-8 -*-
require "rails_helper"

describe Coordinator::NoticesController do
  let(:user) { FactoryGirl.create(:user, :neighborhood_id => Neighborhood.first.id) }
  let(:valid_attributes) { { title: "Hihi", description: "Description", summary: "Summary", neighborhood_id: Neighborhood.first.id, institution_name: "DT Headquarter"} }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # NoticesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  before(:each) do
    pending
  end

  describe "GET show" do
    it "assigns the requested notice as @notice" do
      notice = Notice.create! valid_attributes
      get :show, {:id => notice.to_param}, valid_session
      expect(assigns(:notice)).to eq(notice)
    end
  end

  describe "GET edit" do
    it "assigns the requested notice as @notice" do
      notice = Notice.create! valid_attributes
      get :edit, {:id => notice.to_param}, valid_session
      expect(assigns(:notice)).to eq(notice)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Notice" do
        expect {
          post :create, {:notice => valid_attributes}, valid_session
        }.to change(Notice, :count).by(1)
      end

      it "assigns a newly created notice as @notice" do
        post :create, {:notice => valid_attributes}, valid_session
        expect(assigns(:notice)).to be_a(Notice)
        expect(assigns(:notice)).to be_persisted
      end

      it "redirects to the created notice" do
        post :create, {:notice => valid_attributes}, valid_session
        expect(response).to redirect_to(Notice.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved notice as @notice" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Notice).to receive(:save).and_return(false)
        post :create, {:notice => { "title" => "invalid value" }}, valid_session
        expect(assigns(:notice)).to be_a_new(Notice)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Notice).to receive(:save).and_return(false)
        post :create, {:notice => { "title" => "invalid value" }}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested notice" do
        notice = Notice.create! valid_attributes
        # Assuming there are no other notices in the database, this
        # specifies that the Notice created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        expect_any_instance_of(Notice).to receive(:update_attributes).with({ "title" => "MyString" })
        put :update, {:id => notice.to_param, :notice => { "title" => "MyString" }}, valid_session
      end

      it "assigns the requested notice as @notice" do
        notice = Notice.create! valid_attributes
        put :update, {:id => notice.to_param, :notice => valid_attributes}, valid_session
        expect(assigns(:notice)).to eq(notice)
      end

      it "redirects to the notice" do
        notice = Notice.create! valid_attributes
        put :update, {:id => notice.to_param, :notice => valid_attributes}, valid_session
        expect(response).to redirect_to(notice)
      end
    end

    describe "with invalid params" do
      it "assigns the notice as @notice" do
        notice = Notice.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Notice).to receive(:save).and_return(false)
        put :update, {:id => notice.to_param, :notice => { "title" => "invalid value" }}, valid_session
        expect(assigns(:notice)).to eq(notice)
      end

      it "re-renders the 'edit' template" do
        notice = Notice.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        allow_any_instance_of(Notice).to receive(:save).and_return(false)
        put :update, {:id => notice.to_param, :notice => { "title" => "invalid value" }}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested notice" do
      notice = Notice.create! valid_attributes
      expect {
        delete :destroy, {:id => notice.to_param}, valid_session
      }.to change(Notice, :count).by(-1)
    end

    it "redirects to the notices list" do
      notice = Notice.create! valid_attributes
      delete :destroy, {:id => notice.to_param}, valid_session
      expect(response).to redirect_to(root_url)
    end
  end

  #---------------------------------------------------------------------------

end
