require 'rails_helper'

describe ArticlesHelper, type: :helper do
  describe '#source_to_body' do
    let(:base_xml) do
      <<~XML
        <story>
          <elements>
            <container order="1" element_type="html">
              <field type="paragraph">First paragraph</field>
            </container>
          </elements>
        </story>
      XML
    end

    let(:article) do
      double(
        'Article',
        source: base_xml,
        author: 'Jane Doe',
        hide_author_name: hide_author_name
      )
    end

    context 'when author name is not hidden' do
      let(:hide_author_name) { false }

      it 'renders body HTML and appends an author note container' do
        html = helper.source_to_body(article)

        # paragraph from XML
        expect(html).to include('<p>First paragraph</p>')

        # auto-added author note
        expect(html).to include("<div class='author-note'>")
        expect(html).to include('<p>Jane Doe</p>')
      end
    end

    context 'when author name is hidden' do
      let(:hide_author_name) { true }

      it 'does not append an author note container' do
        html = helper.source_to_body(article)

        expect(html).to include('<p>First paragraph</p>')
        expect(html).not_to include("author-note")
        expect(html).not_to include('Jane Doe')
      end
    end

    context 'when article has no source' do
      let(:hide_author_name) { false }

      it 'returns an empty string' do
        article = double('Article', source: nil, author: 'Jane Doe', hide_author_name: false)
        expect(helper.source_to_body(article)).to eq("")
      end
    end
  end

  describe '#expand_image_tags' do
    let(:body) { 'Intro [File:1|cartoon|ns] Outro' }
    let(:image) do
      double(
        'Image',
        id: 1,
        credit: 'Photographer Name',
        caption: 'A caption',
        width: 600,
        height: 400
      )
    end

    before do
      # Image lookup
      allow(Image).to receive(:find).with('1').and_return(image)

      # data_url can be called with or without args
      allow(image).to receive(:data_url).and_return('http://example.com/image.jpg')

      # Tag helpers – we just need them to return something img-like
      allow(helper).to receive(:retina_image_tag)
        .and_return("<img src='http://example.com/image.jpg' />")
      allow(helper).to receive(:image_tag)
        .and_return("<img src='http://example.com/image.jpg' />")
    end

    it 'replaces [File:id|options] with an image div and meta tags' do
      # Pass a hash so debug[:debug] is safe
      html = helper.expand_image_tags(body, {})

      # basic structure, options "cartoon|ns" should give this class
      expect(html).to include("all-article-images article-image-cartoon no-shadow")

      # the img tag we stubbed
      expect(html).to include("<img src='http://example.com/image.jpg' />")

      # caption & credit divs
      expect(html).to include("<div class='new-image-credit'>Photographer Name</div>")
      expect(html).to include("<div class='new-image-caption'>A caption</div>")

      # schema.org meta tags
      expect(html).to include("itemprop='image'")
      expect(html).to include("itemprop='url'")
      expect(html).to include("itemprop='width'")
      expect(html).to include("itemprop='height'")
    end

    it 'returns empty marker output when image is missing and debug is false' do
      allow(Image).to receive(:find).with('99')
        .and_raise(ActiveRecord::RecordNotFound)

      html = helper.expand_image_tags('X [File:99] Y')

      # the tag should disappear silently
      expect(html).to eq('X  Y')
      expect(html).not_to include('IMAGE 99 NOT FOUND')
    end

    it 'outputs a debug message when image is missing and debug is true' do
      allow(Image).to receive(:find).with('99')
        .and_raise(ActiveRecord::RecordNotFound)

      html = helper.expand_image_tags('X [File:99] Y', true)

      expect(html).to include('=== IMAGE 99 NOT FOUND! ===')
    end
  end
end
