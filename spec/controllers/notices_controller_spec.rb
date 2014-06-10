require 'spec_helper'

describe NoticesController do
  let(:user) { FactoryGirl.create(:user) }

  # This should return the minimal set of attributes required to create a valid
  # Notice. As you add validations to Notice, be sure to
  # adjust the attributes here as well.
  before(:each) do
    @neighborhood = FactoryGirl.create(:neighborhood)
  end

  let(:valid_attributes) { { title: "Hihi", description: "Description", summary: "Summary", neighborhood_id: @neighborhood.id, institution_name: "DT Headquarter"} }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # NoticesController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all notices as @notices" do
      notice = Notice.create! valid_attributes
      get :index, {}, valid_session
      assigns(:notices).should eq([notice])
    end
  end

  describe "GET show" do
    it "assigns the requested notice as @notice" do
      notice = Notice.create! valid_attributes
      get :show, {:id => notice.to_param}, valid_session
      assigns(:notice).should eq(notice)
    end
  end

  describe "GET new" do
    it "assigns a new notice as @notice" do
      get :new, {}, valid_session
      assigns(:notice).should be_a_new(Notice)
    end
  end

  describe "GET edit" do
    it "assigns the requested notice as @notice" do
      notice = Notice.create! valid_attributes
      get :edit, {:id => notice.to_param}, valid_session
      assigns(:notice).should eq(notice)
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
        assigns(:notice).should be_a(Notice)
        assigns(:notice).should be_persisted
      end

      it "redirects to the created notice" do
        post :create, {:notice => valid_attributes}, valid_session
        response.should redirect_to(Notice.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved notice as @notice" do
        # Trigger the behavior that occurs when invalid params are submitted
        Notice.any_instance.stub(:save).and_return(false)
        post :create, {:notice => { "title" => "invalid value" }}, valid_session
        assigns(:notice).should be_a_new(Notice)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Notice.any_instance.stub(:save).and_return(false)
        post :create, {:notice => { "title" => "invalid value" }}, valid_session
        response.should render_template("new")
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
        Notice.any_instance.should_receive(:update_attributes).with({ "title" => "MyString" })
        put :update, {:id => notice.to_param, :notice => { "title" => "MyString" }}, valid_session
      end

      it "assigns the requested notice as @notice" do
        notice = Notice.create! valid_attributes
        put :update, {:id => notice.to_param, :notice => valid_attributes}, valid_session
        assigns(:notice).should eq(notice)
      end

      it "redirects to the notice" do
        notice = Notice.create! valid_attributes
        put :update, {:id => notice.to_param, :notice => valid_attributes}, valid_session
        response.should redirect_to(notice)
      end
    end

    describe "with invalid params" do
      it "assigns the notice as @notice" do
        notice = Notice.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Notice.any_instance.stub(:save).and_return(false)
        put :update, {:id => notice.to_param, :notice => { "title" => "invalid value" }}, valid_session
        assigns(:notice).should eq(notice)
      end

      it "re-renders the 'edit' template" do
        notice = Notice.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Notice.any_instance.stub(:save).and_return(false)
        put :update, {:id => notice.to_param, :notice => { "title" => "invalid value" }}, valid_session
        response.should render_template("edit")
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
      response.should redirect_to(root_url)
    end
  end

  #---------------------------------------------------------------------------

  context "when liking the news" do
    let(:news) { FactoryGirl.create(:notice) }

    before(:each) do
      cookies[:auth_token] = user.auth_token
    end

    it "increments number of likes" do
      expect {
        post :like, :id => news.id
      }.to change(Like, :count).by(1)
    end

    it "decrements number of likes" do
      Like.create(:user_id => user.id, :likeable_id => news.id, :likeable_type => Notice.name)

      expect {
        post :like, :id => news.id
      }.to change(Like, :count).by(-1)
    end

    it "creates a Like instance with correct attributes" do
      post :like, :id => news.id

      like = Like.first
      expect(like.user_id).to eq(user.id)
      expect(like.likeable_id).to eq(news.id)
      expect(like.likeable_type).to eq(news.class.name)
    end
  end

  #---------------------------------------------------------------------------

end
