require 'rails_helper'

describe Article, :type => :model do
  describe '.search' do
    let(:query_params) { { query: 'test', per_page: 5, page: 1 } }

    it 'calls __elasticsearch__.search with the expected query string' do
      expect(Article.__elasticsearch__).to receive(:search).with(hash_including(:query)).and_call_original
      Article.search(query_params)
    end

    it 'respects the per_page parameter' do
      mock_search_result = double("SearchResult").as_null_object
      expect(mock_search_result).to receive(:per).with(5)

      allow(Article.__elasticsearch__).to receive(:search).and_return(mock_search_result)
      Article.search(query_params)
    end

    context 'without show_unpublished' do
      it 'adds a post_filter for unpublished' do
        expect(Article.__elasticsearch__).to receive(:search) do |query_hash|
          expect(query_hash.dig(:query, :bool, :must)).to include(hash_including(term: { unpublished: false }))
          expect(query_hash.dig(:query, :bool, :must)).to include(hash_including(term: { published: true }))
        end.and_call_original
        Article.search(query_params)
      end
    end
  end
end
