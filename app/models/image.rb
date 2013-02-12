class Image < ActiveRecord::Base
  belongs_to :article
  attr_accessible :data, :media_id, :height, :width
  mount_uploader :data, ArticleImageUploader
  validates :media_id, :uniqueness => true

  def self.create_from_media_element(article, media_element)
    assets = 'http://bricolage.sourceforge.net/assets.xsd'
    media_id = media_element["id"]
    file_element = media_element.at_xpath("./assets:file", 'assets' => assets)
    image_as_string = Base64.decode64(file_element.at_xpath("./assets:data", 'assets' => assets).try(:text)).force_encoding("binary")

    sio = StringIO.new(image_as_string)
    sio.class.class_eval { attr_accessor :original_filename, :content_type }
    sio.original_filename = file_element.at_xpath("./assets:name",'assets' => assets ).try(:text)
    sio.content_type = file_element.at_xpath("./assets:media_type",'assets' => assets ).try(:text)

    image = article.images.find_or_create_by_media_id(:media_id => media_id)
    image.data = sio
    image.save
  end

end
