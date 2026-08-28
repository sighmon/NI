require 'rails_helper'

describe "articles/show", type: :view do
  let(:article) { FactoryBot.create(:article) }

  it "shows the article" do
    #get issue_article_path(article.issue,article)
    #get :show, {id: article.id, issue_id: article.issue.id}
    assign(:article, article)
    assign(:issue, article.issue)
    assign(:letters, [])
    assign(:can_read_full_article, true)

    render 
 
    #response.status.should eq(200)
    expect(rendered).to match(/#{article.title}/)
  end

  it "shows two paragraphs and a paywall without exposing the remaining body" do
    article.update!(body: '<p>First paragraph</p><p>Second paragraph</p><p>Paid paragraph</p>')
    assign(:article, article)
    assign(:issue, article.issue)
    assign(:letters, [])
    assign(:can_read_full_article, false)

    render

    expect(rendered).to include(
      'First paragraph',
      'Second paragraph',
      'Subscribe for full access',
      'Subscribe to our digital or bundle magazine for full access to all our content.'
    )
    expect(rendered).not_to include('Paid paragraph')
    expect(rendered).not_to include('Buy this issue')
    expect(rendered).to include('class="paywall"')
    expect(rendered).to include('class="btn btn-danger btn-lg"')
    expect(rendered).to include('class="btn-group paywall-secondary-actions"')
    expect(rendered).to include('role="group"')
    rendered_html = Nokogiri::HTML.fragment(rendered)
    expect(rendered_html.at_css('.paywall-primary-action a')['href']).to eq(
      'https://subscribe.newint.org/?utm_source=PreviewCTA&utm_medium=ArticleSample&utm_campaign=AuSite&utm_id=AuSite'
    )
    expect(rendered_html.css('.paywall-secondary-actions .btn.btn-outline-secondary').length).to eq(1)
  end

end
