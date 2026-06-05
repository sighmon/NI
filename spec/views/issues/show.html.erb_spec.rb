require 'rails_helper'

describe "issues/show", type: :view do
  let(:article) { FactoryBot.create(:article) }
  let(:keynote_article) { FactoryBot.create(:article) }
  let(:issue) { FactoryBot.create(:published_trial_issue) }
  let(:category) { FactoryBot.create(:category) }
  let(:category_two) { FactoryBot.create(:category) }

  before(:each) do
    category.name = "/features/"
    keynote_article.categories << category
    keynote_article.keynote = true
    keynote_article.author = "Jane Doe"
    category_two.name = "/columns/currents/"
    article.categories << category_two
    issue.published = true
    issue.trialissue = true
    issue.articles << keynote_article
    issue.articles << article
    issue.save
    Settings.subscription_price = 600
    Settings.issue_price = 750
  end

    it "renders issue structured data into the head slot" do
      assign(:issue, issue)
      assign(:categories, [category, category_two])
      assign(:web_exclusives, [])
      assign(:blogs, [])
      assign(:page_description, "May, 2026 - Issue teaser")

      render

      structured_data = view.content_for(:structured_data)
      expect(structured_data).to include('type="application/ld+json"')
      expect(structured_data).to include('"@type":"Product"')
      expect(structured_data).to include('"name":"' + issue.title + '"')
      expect(structured_data).to include('"hasPart"')
      expect(structured_data).to include('"author":{"@type":"Person","name":"Jane Doe"}')
    end

    it "should be able to read all articles" do
      # # assign(:article, article)
      assign(:issue, issue)
      assign(:categories, [category, category_two])
      assign(:web_exclusives, [])
      assign(:blogs, [])

      render

      expect(rendered).to include('href="'+issue_article_path(issue, article)+'"')
      expect(rendered).to include('href="'+issue_article_path(issue, keynote_article)+'"')
    end

end
