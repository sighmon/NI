class Image < ActiveRecord::Base

  belongs_to :article
  mount_uploader :data, ArticleImageUploader
  # validates :media_id, uniqueness: true

  # So we can sort images on the article pages via acts as list gem
  acts_as_list

  def self.create_from_media_element(article, media_element)
    assets = 'http://bricolage.sourceforge.net/assets.xsd'
    media_id = media_element["id"]
    file_element = media_element.at_xpath("./assets:file", 'assets' => assets)
    image_as_string = Base64.decode64(file_element.at_xpath("./assets:data", 'assets' => assets).try(:text)).force_encoding("binary")

    sio = StringIO.new(image_as_string)
    sio.class.class_eval { attr_accessor :original_filename, :content_type }
    sio.original_filename = file_element.at_xpath("./assets:name",'assets' => assets ).try(:text)
    sio.content_type = file_element.at_xpath("./assets:media_type",'assets' => assets ).try(:text)

    image = article.images.where(media_id: media_id).first_or_create
    image.caption = image.extract_caption_from_article
    image.credit = image.extract_credit_from_article
    image.data = sio
    image.save
  end

  def self.create_from_uri(article, uri, options = {})

    if not options.nil?
      image_alt_text = options[:alt]
      image_media_id = options[:media_id]
    else
      options = {}
    end

    begin
      response = HTTParty.get(uri)
    rescue Exception => e
      logger.warn "Error: " + e.to_s
      response = Net::HTTPNotFound.new('1.1', 404, nil)
    end

    if response.code >= 200 and response.code < 400
      # image_as_string = Base64.decode64(response.body)
      sio = StringIO.new(response.body)
      sio.class.class_eval { attr_accessor :original_filename, :content_type }
      sio.original_filename = uri.split("/").last
      sio.content_type = response.headers["content-type"]

      if image_media_id
        # It's a header image, so check if it already exists
        image = article.images.where(media_id: image_media_id).first_or_create
      else
        # Try and find it by filename?
        image = article.images.where(data: uri.split("/").last).first_or_create
        image.hidden = true
      end
      image.caption = image_alt_text
      # image.credit = image.extract_credit_from_article
      image.data = sio
      image.save
      return image
    else
      logger.warn "ERROR GETTING IMAGE: #{uri}, RESPONSE: #{response.code}"
      return nil
    end
  end

  def extract_caption_from_article()
    if (not article.nil?) and (not media_id.nil?)
      Nokogiri.XML(self.article.source).at_xpath("//*[@related_media_id=#{media_id}]//*[@type='rel_media_caption']/text()").try(:text)
    end
  end

  def extract_credit_from_article()
    if (not article.nil?) and (not media_id.nil?)
      Nokogiri.XML(self.article.source).at_xpath("//*[@related_media_id=#{media_id}]//*[@type='rel_media_credit']/text()").try(:text)
    end
  end

end
