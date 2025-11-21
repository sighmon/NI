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
end
