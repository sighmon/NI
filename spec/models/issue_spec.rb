require 'rails_helper'

describe Issue, type: :model do
  describe 'callbacks' do
    context 'after_commit' do
      let(:article) { FactoryBot.create(:article) }
      let(:issue) { article.issue }

      it 'flushes cache after save' do
        expect(issue).to receive(:flush_cache)
        issue.save
      end

      it 'reindexes articles after save' do
        expect(issue).to receive(:reindex_articles)
        issue.save
      end
    end
  end

  describe '#display_sections' do
    let(:issue) { FactoryBot.create(:issue) }
    let(:feature_category) { FactoryBot.create(:category, name: '/features/') }
    let(:web_exclusive_category) { FactoryBot.create(:category, name: '/features/web-exclusive/') }
    let(:blog_category) { FactoryBot.create(:category, name: '/blog/') }
    let(:currents_category) { FactoryBot.create(:category, name: '/columns/currents/') }
    let(:feature_article) { FactoryBot.create(:article, issue: issue) }
    let(:web_exclusive_article) { FactoryBot.create(:article, issue: issue) }
    let(:blog_article) { FactoryBot.create(:article, issue: issue) }
    let(:current_article) { FactoryBot.create(:article, issue: issue) }

    before do
      feature_article.categories << feature_category
      web_exclusive_article.categories << web_exclusive_category
      blog_article.categories << blog_category
      current_article.categories << currents_category
    end

    it 'groups articles into the expected show sections' do
      sections = issue.reload.display_sections

      expect(sections[:features]).to contain_exactly(feature_article)
      expect(sections[:web_exclusive]).to contain_exactly(web_exclusive_article)
      expect(sections[:blogs]).to contain_exactly(blog_article)
      expect(sections[:currents]).to contain_exactly(current_article)
    end
  end
end
