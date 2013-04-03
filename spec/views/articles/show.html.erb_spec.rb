require 'spec_helper'

describe "articles/show" do
  let(:article) { FactoryGirl.create(:article) }

  it "shows the article" do
    #get issue_article_path(article.issue,article)
    #get :show, {id: article.id, issue_id: article.issue.id}
    assign(:article, article)
    assign(:issue, article.issue)
    assign(:letters, [])

    render 
 
    #response.status.should eq(200)
    rendered.should match(/#{article.title}/)
  end

end
