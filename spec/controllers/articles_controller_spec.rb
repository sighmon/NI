require 'rails_helper'


describe ArticlesController, type: :controller do

  setup do
    Article.__elasticsearch__.index_name = 'ni-test'
    Article.__elasticsearch__.create_index! force: true
    # Article.__elasticsearch__.import
    # Article.__elasticsearch__.refresh_index!
  end

  context "as a subscriber" do

    before(:each) do
      @user = FactoryBot.create(:subscription).user
      sign_in @user
    end

    context "given an article" do

      let(:article) { FactoryBot.create(:article) }

      let(:issue) { article.issue }

      it "can view the body" do
        get :body, params: {article_id: article.id, issue_id: article.issue.id}
        expect(response.status).to eq(200)
      end 

    end

    context "given an unpublished article" do

      let(:article) { FactoryBot.create(:article, unpublished: true) }

      let(:issue) { article.issue }

      it "can't view the body" do
        get :body, params: {article_id: article.id, issue_id: article.issue.id}
        expect(response.status).to eq(403)
      end

      it "can't show the article" do
        get :show, params: {id: article.id, issue_id: article.issue.id}
        expect(response.status).to eq(302)
      end

    end

    describe "POST push notification" do

      let(:article) { FactoryBot.create(:article) }
      let(:issue) { article.issue }

      it "should not be able to send a push notification" do
        post :send_push_notification, params: {issue_id: issue.id, article_id: article.id}
        expect(response).to redirect_to root_url
      end

    end

  end

  context "as a non-subscriber" do

    before(:each) do
      @user = FactoryBot.create(:user)
      sign_in @user
    end

    describe "GET body" do

      context "given an article" do

        let(:article) { FactoryBot.create(:article) }

        let(:issue) { article.issue }

        it "can't view the body" do
          get :body, params: {article_id: article.id, issue_id: article.issue.id}
          expect(response.status).to eq(403)
        end

      end

    end

    describe "POST push notification" do

      let(:article) { FactoryBot.create(:article) }
      let(:issue) { article.issue }

      it "should not be able to send a push notification" do
        post :send_push_notification, params: {issue_id: issue.id, article_id: article.id}
        expect(response).to redirect_to root_url
      end

    end

  end

  context "as a guest" do

    describe "GET body" do

      context "given an article" do

        let(:article) { FactoryBot.create(:article) }

        let(:issue) { article.issue }

        it "can't view the body" do
          get :body, params: {article_id: article.id, issue_id: article.issue.id}
          expect(response.status).to eq(403)
        end 

      end

    end

    describe "GET popular articles" do

      context "given an article" do

        let(:article) { FactoryBot.create(:article) }

        let(:issue) { article.issue }

        it "can view the popular articles page" do
          get :popular
          expect(response.status).to eq(200)
        end 

      end

    end

    describe "GET quick reads" do

      context "given an article" do

        let(:article) { FactoryBot.create(:article) }

        let(:issue) { article.issue }

        it "can view the quick reads page" do
          get :quick_reads
          expect(response.status).to eq(200)
        end 

      end

    end

    describe "GET search" do

      context "with an article" do

        let!(:issue) { FactoryBot.create(:published_issue) }
        let!(:article) { FactoryBot.create(:article, issue: issue, unpublished: false) }


        before do
          Article.import
          Article.__elasticsearch__.refresh_index!
        end

        it "returns 200 and includes the article in the search results" do
          get :search
          expect(response.status).to eq(200)
          expect(assigns(:articles)).to include(article)
        end

        it "does not include unrelated articles in the search results" do
          get :search, params: { query: 'hello' }
          expect(response.status).to eq(200)
          expect(assigns(:articles)).not_to include(article)
        end

        it "includes the article in the search results when searched by title" do
          get :search, params: { query: article.title }
          expect(response.status).to eq(200)
          expect(assigns(:articles)).to include(article)
        end

        it "doesn't include an unpublished article in the search results when searched by title" do
          article.unpublished = true
          article.save
          Article.import
          Article.__elasticsearch__.refresh_index!
          get :search, params: { query: article.title }
          expect(response.status).to eq(200)
          expect(assigns(:articles)).not_to include(article)
        end

        it "doesn't include an unpublished issue in the search results when searched by title" do
          issue.published = false
          issue.save
          Article.import
          Article.__elasticsearch__.refresh_index!
          get :search, params: { query: article.title }
          expect(response.status).to eq(200)
          expect(assigns(:articles)).not_to include(article)
        end

        it "returns 200 and includes the article in JSON response" do
          get :search, format: :json
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body).first['title']).to eq(article.title)
        end

        it "returns 200 and includes the article in JSON response" do
          get :search, format: :json
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body).first['title']).to eq(article.title)
        end

        it "does not include unrelated articles in the JSON response" do
          get :search, params: { query: 'hello' }, format: :json
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)).to eq([])
        end

        it "includes the article in the JSON results when searched by title" do
          get :search, params: { query: article.title }, format: :json
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body).first['title']).to eq(article.title)
        end

      end

    end

    describe "POST push notification" do

      let(:article) { FactoryBot.create(:article) }
      let(:issue) { article.issue }

      it "should not be able to send a push notification" do
        post :send_push_notification, params: {issue_id: issue.id, article_id: article.id}
        expect(response).to redirect_to root_url
      end

    end

  end


  context "as an admin" do

    before(:each) do
      @user = FactoryBot.create(:admin_user)
      sign_in @user
      @issue = FactoryBot.create(:issue)
    end

    describe "GET show" do
      context "with an article" do

        let(:article) { FactoryBot.create(:article) }

        it "assigns the article" do
          get :show, params: {id: article.id, issue_id: article.issue.id}
          expect(assigns(:article)).to eq(article)
        end

      end
    end

    describe "POST create" do
      context "with valid params" do

        before(:each) do
          @article_attributes = FactoryBot.attributes_for(:article,issue: @issue)
        end

        it "creates a new article" do
          # byebug
          expect {
            post :create, params: {article: @article_attributes, issue_id: @issue.id}
          }.to change(Article, :count).by(1)
        end

        context "with a new category" do
          before(:each) do
            @new_category_attributes = FactoryBot.attributes_for(:category)
          end

          it "creates an article with a new category" do
            #Article.any_instance.should_receive(:categories_attributes=)
            ##ArticlesController.should_receive(:create)
            ##ArticlesController.any_instance.stub(:create) {|*args| ArticlesController.create(*args)}
            #ArticlesController.any_instance.should_receive(:create)
            post :create, params: {article: @article_attributes.merge({ categories_attributes: { "0" => @new_category_attributes }}), issue_id: @issue.id}
            expect(@issue.reload.articles.last.categories.first.name).to eq(@new_category_attributes[:name])
          end

        end

        context "with an existing category" do
          before(:each) do
            @category = Category.create(@category_attributes = FactoryBot.attributes_for(:category))
          end

          it "creates an new article with the category" do
            expect {
              post :create, params: {article: @article_attributes.merge({ categories_attributes: { "0" => @category_attributes }}), issue_id: @issue.id}
            }.to change(Article, :count).by(1)
            expect(@issue.reload.articles.last.categories).to eq([@category])
          end

        end


      end
    end

    describe "PUT update" do
      context "with an existing article" do
     
        before(:each) do
          @article = FactoryBot.create(:article)
        end

        context "and an existing category" do
           
          before(:each) do
            @category_attributes = FactoryBot.attributes_for(:category)
          end

          it "adds the category to the article" do
            put :update, params: {article: {categories_attributes: { "0" => @category_attributes }}, issue_id: @article.issue.id, id: @article.id}

            # why is this different from above?
            #put :update, params: {article: {categories_attributes: { "0" => @category.attributes.slice("name") }}, issue_id: @article.issue.id, id: @article.id}

            # familiar ID error
            #put :update, params: {article: {categories_attributes: { "0" => @category.attributes.slice("id","name") }}, issue_id: @article.issue.id, id: @article.id}

            expect(@article.categories.all.collect(&:name)).to eq([Category.new(@category_attributes).name])
          end

          context "which has already been added to the article" do
            before(:each) do
              @article.categories << Category.new(@category_attributes)
            end

            it "does not add the category to the article" do

              expect {
                put :update, params: {article: {categories_attributes: { "0" => @category_attributes }}, issue_id: @article.issue.id, id: @article.id}
              }.to change(@article.categories, :count).by(0)
            end   
          end
        end
      end
    end

    describe "POST push notification" do

      context "with an article" do

        before(:each) do
          app = Rpush::Apnsp8::App.find_or_create_by(name: ENV.fetch("RPUSH_APPLE_DEVELOPMENT_APP_NAME"))
          app.apn_key = ENV.fetch("APPLE_DEVELOPMENT_APN_KEY")
          app.environment = "sandbox" # APNs environment.
          app.apn_key_id = ENV.fetch("APPLE_DEVELOPMENT_APN_KEY_ID")
          app.team_id = ENV.fetch("INAPP_TEAM_ID")
          app.bundle_id = ENV.fetch("ITUNES_BUNDLE_ID")
          app.connections = 1
          app.save!
        end

        let(:article) { FactoryBot.create(:article) }
        let(:push_registration) { FactoryBot.create(:push_registration) }

        it "should be able to send a push notification" do
          scheduled_test_time = DateTime.now
          input_params = {
            "scheduled_datetime(1i)" => scheduled_test_time.year,
            "scheduled_datetime(2i)" => scheduled_test_time.month,
            "scheduled_datetime(3i)" => scheduled_test_time.day,
            "scheduled_datetime(4i)" => scheduled_test_time.hour,
            "scheduled_datetime(5i)" => scheduled_test_time.minute,
            "device_id" => push_registration.token,
            "alert_text" => "Test message."
          }
          
          post :send_push_notification, params: {issue_id: article.issue.id, article_id: article.id, "/issues/#{article.issue.id}/articles/#{article.id}/send_push_notification" => input_params}
          expect(response).to redirect_to admin_push_notifications_path
        end

      end

    end

  end 

end
