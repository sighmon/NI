class Article < ActiveRecord::Base
  belongs_to :issue
  attr_accessible :author, :body, :publication, :teaser, :title, :trialarticle, :keynote, :source, :featured_image, :featured_image_caption, :featured_image_cache, :remove_featured_image, :categories_attributes, :hide_author_name, :story_id
  mount_uploader :featured_image, FeaturedImageUploader

  # join-model for favourites
  has_many :favourites, :dependent => :destroy
  has_many :users, :through => :favourites

  has_many :images

  has_many :guest_passes, :dependent => :destroy
  has_many :users, :through => :guest_passes

  has_many :article_categorisations
  has_many :categories, :through => :article_categorisations
  accepts_nested_attributes_for :categories, allow_destroy: true
  accepts_nested_attributes_for :images, allow_destroy: true

  include Tire::Model::Search
  include Tire::Model::Callbacks

  # Index name for Heroku Bonzai/elasticsearch
  index_name BONSAI_INDEX_NAME

  def self.search(params, unpublished = false)
    tire.search(load: true, :page => params[:page], :per_page => Settings.article_pagination) do
      query {string params[:query]} if params[:query].present?
      filter :term, :published => true unless unpublished
      sort { by :publication, 'desc' }
    end
  end

  def previous
    my_index = self.issue.ordered_articles.find_index(self)
    previous_index = my_index-1
    if previous_index < 0
      return nil
    else
      return self.issue.ordered_articles[previous_index]
    end
  end

  def next
    my_index = self.issue.ordered_articles.find_index(self)
    return self.issue.ordered_articles[my_index+1]
  end

  mapping do
    indexes :id, type: 'integer'
    indexes :title
    indexes :teaser
    indexes :category
    indexes :author
    indexes :body
    indexes :featured_image_caption
    indexes :publication, type: 'date'
    indexes :published, type: 'boolean', as: 'published'
  end

  # Fix so that nested Categories can be found and saved for Articles if they exist
  def categories_attributes=(categories_attributes)
    categories_attributes.values.each do |category_attributes|
      if category_attributes[:id].nil? and category_attributes[:name].present?
        category = Category.find_by_name(category_attributes[:name])
        if category.present?
          category_attributes[:id] = category.id
          ## FIXME? check if we are adding twice?
          self.categories << category
        end
      end
    end
    assign_nested_attributes_for_collection_association(:categories, categories_attributes.values, mass_assignment_options)
  end

  def create_categories_from_article_source
    if self.categories.blank?
      assets = 'http://bricolage.sourceforge.net/assets.xsd'
      if not self.source.blank?
        doc = Nokogiri::XML(self.source)
        category_list = doc.xpath(".//category",'assets' => assets)
        category_list.collect do |cat|
          c = Category.create_article_from_element(self,cat)
        end
      end
    else
      logger.info "**** This Article already has categories ****"
    end
    return self.categories
  end

  def published
    issue.published
  end

  # Guest pass checking
  def is_valid_guest_pass(key)
    pass = self.guest_passes.where(:key => key).first
    if pass
      pass.last_used = DateTime.now
      pass.use_count += 1
      pass.save
      return true
    else
      return false
    end
  end

  def extract_media_ids_from_source
    related_media = Nokogiri::XML(self.source).xpath('//container[@element_type="related_media"]').collect{|e| e["related_media_id"]}.select{|i|i}
    related_media_graphic = Nokogiri::XML(self.source).xpath('//container[@element_type="related_media_graphic"]').collect{|e| e["related_media_id"]}.select{|i|i}
    if not related_media_graphic.empty?
      return related_media << related_media_graphic
    else 
      return related_media
    end
  end

  # TODO: make private
  # private

  def import_media_from_bricolage(opts = {})
    # media_ids = self.extract_media_ids_from_source, force = false

    media_ids = opts[:media_ids] || self.extract_media_ids_from_source
    force = opts[:force] || false

    # Check for previously imported images

    if not force
      media_ids = media_ids.select{|i| Image.find_by_media_id(i).try(:data_url).nil?}
    end

    if media_ids.empty?
      return
    end

    #HTTPI.log_level = :debug
    HTTPI.adapter = :curb
    Savon.configure do |config|
      config.env_namespace = :soap
    end
    client = Savon.client do
      wsdl.endpoint = "https://bric-new.newint.org/soap"
      # wsdl.endpoint = "http://pixpad.local"
      wsdl.namespace = "http://bricolage.sourceforge.net/Bric/SOAP/Auth"
      http.auth.ssl.verify_mode = :none
    end
    response = client.request "auth", "login" do
      # "env:encodingStyle" => "http://schemas.xmlsoap.org/soap/encoding/"
      http.headers["SOAPAction"] = "\"http://bricolage.sourceforge.net/Bric/SOAP/Auth#login\""
      soap.element_form_default = :qualified
      soap.body = {
        "username" => ENV["BRICOLAGE_USERNAME"],
        "password" => ENV["BRICOLAGE_PASSWORD"],
        :attributes! => { 
          "username" => { "xsi:type" => "xsd:string" }, 
          "password" => { "xsi:type" => "xsd:string" }
        }
      }
    end
    # Pull the media from the media_id
    media_id_block = media_ids.collect{|id| '<media_id xsi:type="xsd:int">%s</media_id>' % id}.join("\n")
    response = client.request "media", "media_ids" do
      http.headers["SOAPAction"] = "\"http://bricolage.sourceforge.net/Bric/SOAP/Media#export\""
      http.set_cookies(response.http)
      soap.element_form_default = :qualified
      # TODO: implement article import
      soap.xml = '<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" 
    xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
    soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" 
    xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <export xmlns="http://bricolage.sourceforge.net/Bric/SOAP/Media">
      <media_ids soapenc:arrayType="xsd:int[%d]" xsi:type="soapenc:Array">
        %s
      </media_ids>
    </export>
  </soap:Body>
</soap:Envelope>' % [media_ids.length, media_id_block]
    end
    doc = Nokogiri::XML(Base64.decode64(response[:export_response][:document]).force_encoding("UTF-8"))
    images = doc.xpath("//assets:media",'assets' => 'http://bricolage.sourceforge.net/assets.xsd')
    images.collect do |element|
      Image.create_from_media_element(self,element)
    end
    # Process XML
    # Pull out image name

    # inside a loop

    # string as data
  end

  def get_story_id
    return Nokogiri.XML(source).at_xpath("/story").try(:[],:id).try(:to_i)
  end

end
