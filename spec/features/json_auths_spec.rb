require 'spec_helper'

feature "JSON Authentication" do


  given(:subscriber) { FactoryGirl.create(:subscription).user }

  given(:article) { FactoryGirl.create(:article) }

  background do
    path = user_session_path(username: subscriber.username, password: subscriber.password, format: :json)
    Rails.logger.info("get a new session from #{path}")
    visit path
    Rails.logger.info("got a new session")
    page.status_code.should eq(200)
    show_me_the_cookies
  end

  scenario "can read the body" do
    path = issue_article_body_path(issue_id: article.issue.id, article_id: article.id)
    Rails.logger.info("get an article from #{path}")
    show_me_the_cookies
    visit path
    Rails.logger.info("got an article")
    page.status_code.should eq(200)
  end
end
