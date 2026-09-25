require 'rails_helper'

describe IssuesHelper, type: :helper do
  describe 'column images by publication date' do
    {
      africa: {
        '2022-12-31' => 'section-view-from-africa-issue.jpg',
        '2023-01-01' => 'section-view-from-africa-issue-2023.jpg',
        '2026-01-01' => 'section-view-from-africa-issue-2023.jpg'
      },
      india: {
        '2024-09-01' => 'section-view-from-india-issue.png',
        '2025-08-31' => 'section-view-from-india-issue.png',
        '2025-09-01' => 'section-view-from-india-issue-2025.png',
        '2026-01-01' => 'section-view-from-india-issue-2025.png',
        '2026-08-31' => 'section-view-from-india-issue-2025.png'
      }
    }.each do |column, dates|
      dates.each do |publication, image|
        it "uses #{image} for #{column} on #{publication}" do
          article = double('Article', publication: Date.parse(publication))

          expect(helper.public_send("issue_view_from_#{column}_image", article)).to eq(image)
        end
      end
    end
  end

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
