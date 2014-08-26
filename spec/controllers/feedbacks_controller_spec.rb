require 'spec_helper'

describe FeedbacksController do

  # This should return the minimal set of attributes required to create a valid
  # Feedback. As you add validations to Feedback, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { { title: "MyString", email: Faker::Internet.email, name: "Example Name", message: "Example message"} }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # FeedbacksController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all feedbacks as @feedbacks" do
      feedback = Feedback.create! valid_attributes
      get :index, {}, valid_session
      assigns(:feedbacks).should eq([feedback])
    end
  end

  describe "GET show" do
    it "assigns the requested feedback as @feedback" do
      feedback = Feedback.create! valid_attributes
      get :show, {:id => feedback.to_param}, valid_session
      assigns(:feedback).should eq(feedback)
    end
  end

  describe "GET new" do
    it "assigns a new feedback as @feedback" do
      get :new, {}, valid_session
      assigns(:feedback).should be_a_new(Feedback)
    end
  end

  describe "GET edit" do
    it "assigns the requested feedback as @feedback" do
      feedback = Feedback.create! valid_attributes
      get :edit, {:id => feedback.to_param}, valid_session
      assigns(:feedback).should eq(feedback)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Feedback" do
        expect {
          post :create, {:feedback => valid_attributes}, valid_session
        }.to change(Feedback, :count).by(1)
      end

      it "assigns a newly created feedback as @feedback" do
        post :create, {:feedback => valid_attributes}, valid_session
        assigns(:feedback).should be_a(Feedback)
        assigns(:feedback).should be_persisted
      end

      it "redirects to the home page" do
        post :create, {:feedback => valid_attributes}, valid_session
        response.should redirect_to(root_path)
      end
    end

    # describe "with invalid params" do
    #   it "assigns a newly created but unsaved feedback as @feedback" do
    #     # Trigger the behavior that occurs when invalid params are submitted
    #     Feedback.any_instance.stub(:save).and_return(false)
    #     post :create, {:feedback => { "title" => "invalid value" }}, valid_session
    #     assigns(:feedback).should be_a_new(Feedback)
    #   end

    #   it "re-renders the 'new' template" do
    #     # Trigger the behavior that occurs when invalid params are submitted
    #     Feedback.any_instance.stub(:save).and_return(false)
    #     post :create, {:feedback => { "title" => "invalid value" }}, valid_session
    #     response.should render_template("new")
    #   end
    # end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested feedback" do
        feedback = Feedback.create! valid_attributes
        # Assuming there are no other feedbacks in the database, this
        # specifies that the Feedback created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Feedback.any_instance.should_receive(:update_attributes).with({ "title" => "MyString" })
        put :update, {:id => feedback.to_param, :feedback => { "title" => "MyString" }}, valid_session
      end

      it "assigns the requested feedback as @feedback" do
        feedback = Feedback.create! valid_attributes
        put :update, {:id => feedback.to_param, :feedback => valid_attributes}, valid_session
        assigns(:feedback).should eq(feedback)
      end

      it "redirects to the feedback" do
        feedback = Feedback.create! valid_attributes
        put :update, {:id => feedback.to_param, :feedback => valid_attributes}, valid_session
        response.should redirect_to(feedback)
      end
    end

    describe "with invalid params" do
      it "assigns the feedback as @feedback" do
        feedback = Feedback.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Feedback.any_instance.stub(:save).and_return(false)
        put :update, {:id => feedback.to_param, :feedback => { "title" => "invalid value" }}, valid_session
        assigns(:feedback).should eq(feedback)
      end

      it "re-renders the 'edit' template" do
        feedback = Feedback.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Feedback.any_instance.stub(:save).and_return(false)
        put :update, {:id => feedback.to_param, :feedback => { "title" => "invalid value" }}, valid_session
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested feedback" do
      feedback = Feedback.create! valid_attributes
      expect {
        delete :destroy, {:id => feedback.to_param}, valid_session
      }.to change(Feedback, :count).by(-1)
    end

    it "redirects to the feedbacks list" do
      feedback = Feedback.create! valid_attributes
      delete :destroy, {:id => feedback.to_param}, valid_session
      response.should redirect_to(feedbacks_url)
    end
  end

end
