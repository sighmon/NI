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

describe ImagesController, :type => :controller do

  # This should return the minimal set of attributes required to create a valid
  # Image. As you add validations to Image, be sure to
  # update the return value of this method accordingly.
  def valid_attributes_for_image(image)
    image.attributes.except("id", "article_id", "created_at", "updated_at") 
  end

  def valid_attributes
    valid_attributes_for_image(FactoryGirl.build(:image))
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # ImagesController. Be sure to keep this updated too.
  def valid_session
    {}
  end

  context "as a guest" do

    describe "GET index" do
      it "redirects to home" do
        image = FactoryGirl.create(:image)
        get :index, {:issue_id => image.article.issue.id, :article_id => image.article.id}
        expect(response).to redirect_to(issues_url)
      end
    end

    describe "POST create" do
      describe "with valid params" do
        it "does not create a new Image" do
          expect {
            image = FactoryGirl.build(:image)
            post :create, {:image => valid_attributes_for(image), :article_id => image.article.id, :issue_id => image.article.issue.id}
          }.to change(Image, :count).by(0)
        end

        it "redirects to the issues" do
          image = FactoryGirl.build(:image)
          post :create, {:image => valid_attributes_for(image), :article_id => image.article.id, :issue_id => image.article.issue.id}
          expect(response).to redirect_to(issues_path)
        end
      end

    end

    describe "PUT update" do
      describe "with valid params" do
        it "should not call update_attributes" do
          image = FactoryGirl.create(:image)
          # Assuming there are no other images in the database, this
          # specifies that the Image created on the previous line
          # receives the :update_attributes message with whatever params are
          # submitted in the request.
          expect_any_instance_of(Image).not_to receive(:update_attributes)
          put :update, {:id => image.to_param, :image => { :these => "params" }, :article_id => image.article.id, :issue_id => image.article.issue.id}
        end

        it "redirects to the issues" do
          image = FactoryGirl.create(:image)
          put :update, {:id => image.to_param, :image => valid_attributes_for_image(image), :article_id => image.article.id, :issue_id => image.article.issue.id} 
          expect(response).to redirect_to(issues_path)
        end
      end

      describe "with invalid params" do
        it "assigns the image as @image" do
          image = FactoryGirl.create(:image)
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Image).to receive(:save).and_return(false)
          put :update, {:id => image.to_param, :image => {  }, :article_id => image.article.id, :issue_id => image.article.issue.id}
          expect(assigns(:image)).to eq(image)
        end

      end
    end

    describe "DELETE destroy" do
      it "should not destroy any images" do
        image = FactoryGirl.create(:image)
        expect {
          delete :destroy, {:id => image.to_param, :article_id => image.article.id, :issue_id => image.article.issue.id}
        }.to change(Image, :count).by(0)
      end

      it "redirects to issues" do
        image = FactoryGirl.create(:image)
        delete :destroy, {:id => image.to_param, :article_id => image.article.id, :issue_id => image.article.issue.id}
        expect(response).to redirect_to(issues_path)
      end
    end
  end

  context "as an admin" do

    before (:each) do
      @user = FactoryGirl.create(:admin_user)
      sign_in @user
    end

    describe "GET index" do
      it "assigns all images as @images" do
        image = FactoryGirl.create(:image)
        get :index, {:issue_id => image.article.issue_id, :article_id => image.article_id}
        expect(assigns(:images)).to eq([image])
      end
    end

    describe "GET new" do
      it "assigns a new image as @image" do
        article = FactoryGirl.create(:article)
        get :new, {:issue_id => article.issue.id, :article_id => article.id}
        expect(assigns(:image)).to be_a_new(Image)
      end
    end

    describe "GET show" do
      it "assigns the requested image as @image" do
        image = FactoryGirl.create(:image)
        get :show, {:id => image.id, :issue_id => image.article.issue.id, :article_id => image.article.id}
        expect(assigns(:image)).to eq(image)
      end
    end


    describe "GET edit" do
      it "assigns the requested image as @image" do
        image = FactoryGirl.create(:image)
        get :edit, {:id => image.to_param, :article_id => image.article.id, :issue_id => image.article.issue.id}
        expect(assigns(:image)).to eq(image)
      end
    end

    describe "POST create" do
      describe "with valid params" do
        it "creates a new Image" do
          expect {
            image = FactoryGirl.build(:image)
            post :create, {:image => valid_attributes_for(image), :article_id => image.article.id, :issue_id => image.article.issue.id}
          }.to change(Image, :count).by(1)
        end

        it "assigns a newly created image as @image" do
          image = FactoryGirl.build(:image)
          post :create, {:image => valid_attributes_for(image), :article_id => image.article.id, :issue_id => image.article.issue.id}
          expect(assigns(:newimage)).to be_a(Image)
          expect(assigns(:newimage)).to be_persisted
        end

        it "redirects to the article" do
          image = FactoryGirl.build(:image)
          post :create, {:image => valid_attributes_for(image), :article_id => image.article.id, :issue_id => image.article.issue.id}
          expect(response).to redirect_to(issue_article_path(image.article.issue,image.article))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved image as @image" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Image).to receive(:save).and_return(false)
          article = FactoryGirl.create(:article)
          post :create, {:image => {  }, :article_id => article.id, :issue_id => article.issue.id, :formats => [:js]}
          expect(assigns(:image)).to be_a_new(Image)
        end

        it "re-renders the 'new' template" do
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Image).to receive(:save).and_return(false)
          article = FactoryGirl.create(:article)
          post :create, {:image => {  }, :article_id => article.id, :issue_id => article.issue.id}
          expect(response).to render_template("new")
        end
      end
    end

    describe "PUT update" do
      describe "with valid params" do
        it "updates the requested image" do
          image = FactoryGirl.create(:image)
          # Assuming there are no other images in the database, this
          # specifies that the Image created on the previous line
          # receives the :update_attributes message with whatever params are
          # submitted in the request.
          expect_any_instance_of(Image).to receive(:update_attributes).with({ "these" => "params" })
          put :update, {:id => image.to_param, :image => { :these => "params" }, :article_id => image.article.id, :issue_id => image.article.issue.id}
        end

        it "assigns the requested image as @image" do
          image = FactoryGirl.create(:image)
          put :update, {:id => image.to_param, :image => valid_attributes_for_image(image), :article_id => image.article.id, :issue_id => image.article.issue.id}
          expect(assigns(:image)).to eq(image)
        end

        it "redirects to the image" do
          image = FactoryGirl.create(:image)
          put :update, {:id => image.to_param, :image => valid_attributes_for_image(image), :article_id => image.article.id, :issue_id => image.article.issue.id} 
          expect(response).to redirect_to(issue_article_image_path(image.article.issue,image.article,image))
        end
      end

      describe "with invalid params" do
        it "assigns the image as @image" do
          image = FactoryGirl.create(:image)
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Image).to receive(:save).and_return(false)
          put :update, {:id => image.to_param, :image => {  }, :article_id => image.article.id, :issue_id => image.article.issue.id}
          expect(assigns(:image)).to eq(image)
        end

        it "re-renders the 'edit' template" do
          image = FactoryGirl.create(:image)
          # Trigger the behavior that occurs when invalid params are submitted
          allow_any_instance_of(Image).to receive(:save).and_return(false)
          put :update, {:id => image.to_param, :image => {  }, :article_id => image.article.id, :issue_id => image.article.issue.id}
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE destroy" do
      it "destroys the requested image" do
        image = FactoryGirl.create(:image)
        expect {
          delete :destroy, {:id => image.to_param, :article_id => image.article.id, :issue_id => image.article.issue.id}
        }.to change(Image, :count).by(-1)
      end

      it "redirects to the images list" do
        image = FactoryGirl.create(:image)
        delete :destroy, {:id => image.to_param, :article_id => image.article.id, :issue_id => image.article.issue.id}
        expect(response).to redirect_to(issue_article_images_path(image.article.issue,image.article))
      end
    end

  end


end
