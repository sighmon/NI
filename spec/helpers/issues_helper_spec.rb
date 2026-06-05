require 'rails_helper'

describe IssuesHelper, type: :helper do
  describe '#issue_article_structured_data_image' do
    it 'builds image data from the first article image' do
      image = double(
        'Image',
        data_url: 'https://example.com/article.jpg',
        width: 1200,
        height: 800
      )
      article = double(
        'Article',
        featured_image: nil,
        first_image: image
      )

      expect(helper.issue_article_structured_data_image(article)).to eq(
        "@type" => "ImageObject",
        "url" => "https://example.com/article.jpg",
        "width" => 1200,
        "height" => 800
      )
    end
  end
end
