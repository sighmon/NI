require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe Institution::UsersController, :type => :controller do

  # This should return the minimal set of attributes required to create a valid
  # Institution::User. As you add validations to Institution::User, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {  }
  end


  context "as a parent" do
    let(:child) { FactoryBot.create(:child_user) }
    let(:parent) { child.parent }

    before(:each) do
      sign_in parent
    end
      
    describe "GET index" do

      it "works" do
        get :index
        expect(response.status).to eq(200)
      end

      it "assigns all children as @users" do
        get :index
        expect(assigns(:users)).to eq(parent.children)
      end
    end

    describe "GET show" do

      it "assigns the requested user as @user" do
        get :show, params: {:id => child.to_param}
        expect(assigns(:user)).to eq(child)
      end
    end

    describe "GET new" do
      it "assigns a new user as @user" do
        get :new
        expect(assigns(:user)).to be_a_new(User)
      end
    end

    describe "GET edit" do

      it "assigns the requested user as @user" do
        get :edit, params: {:id => child.to_param}
        expect(assigns(:user)).to eq(child)
      end
    end

    describe "POST create" do
      describe "with valid params" do
        let(:attributes) { FactoryBot.attributes_for(:institution_user) }
        it "creates a new User" do
          expect {
            post :create, params: {:user => attributes}
          }.to change{parent.children.count}.by(1)
        end

        it "assigns a newly created user as @user" do
          post :create, params: {:user => attributes}
          expect(assigns(:user)).to be_a(User)
          expect(assigns(:user)).to be_persisted
        end

        it "redirects to the parent user page" do
          post :create, params: {:user => attributes}
          expect(response).to redirect_to(parent)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved user as @user" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(User).to receive(:save).and_return(false)
          post :create, params: {:user => {  }}
          expect(assigns(:user)).to be_a_new(User)
        end

        it "re-renders the 'new' template" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(User).to receive(:save).and_return(false)
          post :create, params: {:user => {  }}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT update" do
      describe "with valid params" do
        it "updates the requested user" do
          user = child
          # Assuming there are no other institution_users in the database, this
          # specifies that the Institution::User created on the previous line
          # receives the :update message with whatever params are
          # submitted in the request.
          child_user_params = FactoryBot.attributes_for(:child_user)
          # TOFIX: Ugly hack merging uk_id & uk_expiry to "" insetad of nil
          child_user_action_params = ActionController::Parameters.new(child_user_params.merge({uk_id: "",uk_expiry: ""})).permit(:username, :email, :uk_id, :uk_expiry, :password, :password_confirmation)
          # byebug
          expect_any_instance_of(User).to receive(:update).with(child_user_action_params)
          put :update, params: {:id => user.to_param, :user => child_user_params}
        end

        it "assigns the requested user as @user" do
          user = FactoryBot.create(:user)
          put :update, params: {:id => user.to_param, :user => FactoryBot.attributes_for(:user)}
          expect(assigns(:user)).to eq(user)
        end

        it "redirects to the parent" do
          user = child
          put :update, params: {:id => user.to_param, :user => FactoryBot.attributes_for(:child_user)}
          expect(response).to redirect_to(parent)
        end
      end

      describe "with invalid params" do
        it "assigns the user as @user" do
          user = FactoryBot.create(:user)
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(User).to receive(:save).and_return(false)
          put :update, params: {:id => user.to_param, :user => {  }}
          expect(assigns(:user)).to eq(user)
        end

        it "re-renders the 'edit' template" do
          user = child
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(User).to receive(:save).and_return(false)
          put :update, params: {:id => user.to_param, :user => {  }}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE destroy" do
      it "destroys the requested institution_user" do
        user = child
        expect {
          delete :destroy, params: {:id => user.to_param}
        }.to change(User, :count).by(-1)
      end

      it "redirects to the parent" do
        user = child
        delete :destroy, params: {:id => user.to_param}
        expect(response).to redirect_to(parent)
      end
    end

  end

end
