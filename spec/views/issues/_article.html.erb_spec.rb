require 'rails_helper'

describe 'issues/_article', type: :view do
  let(:article) { FactoryBot.create(:article) }

  [true, false].each do |can_read|
    ['2026-08-31', '2026-09-01', '2027-01-01', '2027-08-31'].each do |date|
      it "shows the correct Brazil image on #{date} with read access #{can_read}" do
        publication = Date.parse(date)
        article.update!(publication: publication)
        allow(article).to receive(:featured_image).and_return(nil)
        allow(article).to receive(:first_image).and_return(nil)
        allow(article).to receive(:has_category).and_return(false)
        allow(article).to receive(:has_category).with('/columns/view-from-brazil/').and_return(true)
        allow(view).to receive(:can?).and_return(false)
        allow(view).to receive(:can?).with(:read, article).and_return(can_read)
        assign(:issue, article.issue)

        render partial: 'issues/article', locals: { article: article }

        suffix = publication >= Date.new(2026, 9, 1) ? '-2026' : ''
        image = "section-view-from-brazil-issue#{suffix}.png"
        html = Nokogiri::HTML.fragment(rendered)
        expect(html.at_css('img.article-thumb')['src']).to eq(view.image_path(image))
        expect(html.at_css('[itemtype="https://schema.org/ImageObject"] meta[itemprop="url"]')['content']).to eq(view.image_url(image))
      end
    end
  end
end
