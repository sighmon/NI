class Image < ActiveRecord::Base
  belongs_to :article
  attr_accessible :data, :media_id, :height, :width, :caption, :credit, :hidden
  mount_uploader :data, ArticleImageUploader
  # validates :media_id, :uniqueness => true

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

    image = article.images.where(:media_id => media_id).first_or_create
    image.caption = image.extract_caption_from_article
    image.credit = image.extract_credit_from_article
    image.data = sio
    image.save
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
