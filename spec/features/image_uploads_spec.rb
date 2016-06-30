require 'rails_helper'

# gives us login_as which devise uses internally
include Warden::Test::Helpers


describe "ImageUploads", :type => :feature do

  #before(:each) do
  #end

  context "as an admin" do
    let(:admin) { FactoryGirl.create(:admin_user) }

    before(:each) do
      # poke the warden helper to login
      login_as admin, scope: :user
    end

    context "given an article" do

      let(:article) { FactoryGirl.create(:article) }

      describe "GET /issue/:id/article/:id/images/new" do
        it "works! (now write some real specs)" do
          # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
          visit new_issue_article_image_path(article.issue.id,article.id)
          #click_button("New")
          attach_file('image_data', Rails.root.join('spec/factories','test-image.jpg'))
          click_button("Create Image")
          expect(page.status_code).to eq(200)
        end
      end


      describe "GET /issue/:id/article/:id" do
        it "works" do
          visit issue_article_path(article.issue,article)
          expect(page.status_code).to eq(200)
          expect(page).to have_content(article.title)
        end

        # TODO: Get pix to fix upload test.. maybe.. it's not critical.
        # it "can add upload files", :js => true do

        #   #def wait_until
        #   #  require "timeout"
        #   #  Timeout.timeout(Capybara.default_wait_time) do
        #   #    sleep(0.1) until value = yield
        #   #    value
        #   #  end
        #   #end

        #   pending "can't seem to trigger jquery-image-upload"
        #   ##pp "running can upload"
        #   Rails.logger.info("### trying to upload")
        #   visit issue_article_path(article.issue,article)
        #   Rails.logger.info("### attach")
        #   attach_file('image_data', Rails.root.join('factories','test-image.jpg'))
        #   # form has no button so submit it with javascript... hrmmm
        #   Rails.logger.info("### force submit")
        #   page.execute_script("$('form#new_image').submit()")
        #   ## ... nothing seems to happen
        #   #pp article.images
        #   #wait_until { !page.driver.alert_messages.empty? }
        #   Rails.logger.info("### done")
        # end
      end
    end
  end
end
