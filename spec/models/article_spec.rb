require 'rails_helper'

RSpec.describe Article, type: :model do
  describe '.search' do
    let(:query_params) { { query: 'test', page: 1 } }

    # Fake ES backend: search will return an object that responds to #records
    let(:search_result) { double('SearchResult', records: []) }
    let(:es_backend)    { double('__elasticsearch__ backend', search: search_result) }

    before do
      # Make Article.__elasticsearch__ return our fake backend
      allow(Article).to receive(:__elasticsearch__).and_return(es_backend)
    end

    it 'calls __elasticsearch__.search with the expected query string' do
      Article.search(query_params)

      expect(es_backend).to have_received(:search) do |query_hash|
        # At least has a :query key
        expect(query_hash).to include(:query)
      end
    end

    context 'without show_unpublished' do
      it 'adds must conditions for unpublished: false and published: true' do
        Article.search(query_params)

        expect(es_backend).to have_received(:search) do |query_hash|
          must = query_hash.dig(:query, :bool, :must)
          expect(must).to include(term: { unpublished: false })
          expect(must).to include(term: { published: true })
        end
      end
    end
  end
end
