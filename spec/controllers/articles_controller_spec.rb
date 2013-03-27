require 'spec_helper'


describe ArticlesController do

  context "as an admin" do

    before(:each) do
      @user = FactoryGirl.create(:admin_user)
      sign_in @user
      @issue = FactoryGirl.create(:issue)
    end

    describe "POST create" do
      context "with valid params" do

        before(:each) do
          @article = FactoryGirl.build(:article,issue: @issue)
        end

        it "creates a new article" do
          expect {
            post :create, {:article => @article, :issue_id => @article.issue.id}
          }.to change(Article, :count).by(1)
        end

        context "with a new category" do
          before(:each) do
            @new_category = FactoryGirl.build(:category)
          end

          it "creates an article with a new category" do
            #Article.any_instance.should_receive(:categories_attributes=)
            ##ArticlesController.should_receive(:create)
            ##ArticlesController.any_instance.stub(:create) {|*args| ArticlesController.create(*args)}
            #ArticlesController.any_instance.should_receive(:create)
            post :create, {:article => valid_attributes_for(@article).merge({ :categories_attributes => { "0" => valid_attributes_for(@new_category) }}), :issue_id => @article.issue.id}
            @issue.articles.last.categories.first.name.should eq(@new_category.name)
          end

        end

        context "with an existing category" do
          before(:each) do
            @category = FactoryGirl.create(:category)
          end

          it "creates an new article with the category" do
            #Article.any_instance.should_receive(:categories_attributes=)
            expect {
              #debugger
              post :create, {:article => valid_attributes_for(@article).merge({ :categories_attributes => { "0" => valid_attributes_for(@category) }}), :issue_id => @article.issue.id}
              #pp response 
            }.to change(Article, :count).by(1)
            @issue.articles.last.categories.should eq([@category])
          end

        end


      end
    end

    describe "PUT update" do
      context "with an existing article" do
     
        before(:each) do
          @article = FactoryGirl.create(:article)
        end

        context "and an existing category" do
           
          before(:each) do
            @category = FactoryGirl.create(:category)
          end

          it "adds the category to the article" do
            put :update, {:article => {:categories_attributes => { "0" => valid_attributes_for(@category) }}, :issue_id => @article.issue.id, :id => @article.id}

            # why is this different from above?
            #put :update, {:article => {:categories_attributes => { "0" => @category.attributes.slice("name") }}, :issue_id => @article.issue.id, :id => @article.id}

            # familiar ID error
            #put :update, {:article => {:categories_attributes => { "0" => @category.attributes.slice("id","name") }}, :issue_id => @article.issue.id, :id => @article.id}

            @article.categories.should eq([@category])
          end
 
        end

      end
    end

  end 

end
