class Article < ActiveRecord::Base

  belongs_to :issue
  
  mount_uploader :featured_image, FeaturedImageUploader

  # join-model for favourites
  has_many :favourites, :dependent => :destroy
  has_many :users, :through => :favourites

  has_many :images

  has_many :guest_passes, :dependent => :destroy
  has_many :users, :through => :guest_passes

  has_many :article_categorisations
  has_many :categories, :through => :article_categorisations
  accepts_nested_attributes_for :categories, allow_destroy: true, reject_if: :category_exists
  accepts_nested_attributes_for :images, allow_destroy: true

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  # Index name for Heroku Bonzai/elasticsearch
  index_name BONSAI_INDEX_NAME


  def self.search(params, show_unpublished = false)
    results_per_page = Settings.article_pagination
    clean_query = params[:query].try(:gsub, /[^0-9a-z "]/i, '')
    if params[:per_page] and (params[:per_page].to_i > 0)
      results_per_page = params[:per_page].to_i
    end
    query_hash = {
      sort: [{ publication: { order: "desc", "unmapped_type": "long"} }]
    }
    query_hash.merge!({query: { query_string: { query: clean_query, default_operator: "AND" }}}) if params[:query].present?
    # TOFIX: Elasticsearch 5 won't post_filter on published, so using unpubilshed, which doesn't take into account unpublished issues.
    query_hash.merge!({ post_filter: { term: { unpublished: false}} }) unless show_unpublished

    __elasticsearch__.search(query_hash).page(params[:page]).per(results_per_page).records
  end

  def score
    # Article score is based on guest_pass use_count and reduces over time.
    # logger.info "Use count: " + self.total_guest_passes_use_count.to_s
    age_in_seconds = Time.now - self.publication
    mm, ss = age_in_seconds.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)
    age_in_days = dd
    # logger.info "Age: " + age_in_days.to_s

    # Article score algorithm
    # score_drop = 1000
    # maximum_score = 10.0
    # (score_drop / (age_in_days + (score_drop/maximum_score))) * (self.total_guest_passes_use_count/maximum_score)

    # Decay algorithm from https://github.com/clux/decay/blob/master/decay.js
    gravity = 1.1
    hour_age = (Time.now() - self.publication) / (1000 * 3600);
    return (self.total_guest_passes_use_count - 1) / ((hour_age + 2) ** gravity)
  end

  def total_guest_passes_use_count
    self.guest_passes.all.inject(0) { |acc,guest_pass| acc + guest_pass.use_count }
  end

  def self.popular
    # Returns the 12 most popular articles shared via guest passes and sorted by score
    Rails.cache.fetch("popular_guest_passes", expires_in: 6.hours) do
      # Need .to_a here otherwise it caches the scope, not the result of the query
      # GuestPass.order(:use_count).reverse.first(12).to_a

      # Most popular 12 articles sorted by score
      Article.all.sort_by(&:score).reverse.first(12)
    end
  end

  def popular_guest_pass
    # Find or create a guest pass for the user 'popular' so that popular gets the guest_pass clicks and uses rather than corrupting the actual guest_pass clicks
    GuestPass.find_or_create_by(:user_id => User.find_by_username("popular").id, :article_id => self.id)
  end

  def popular_guest_pass_key
    # Used in the JSON feed for newint.com.au
    popular_guest_pass.key
  end

  def previous
    my_index = self.issue.ordered_articles.find_index(self)
   
    # the decrement fails  if we don't find ourselves in the ordered list (eg, we are uncategorized)
    return nil if my_index.nil?

    previous_index = my_index-1
    
    if previous_index < 0
      return nil
    else
      return self.issue.ordered_articles[previous_index]
    end
  end

  def next
    my_index = self.issue.ordered_articles.find_index(self)
    return nil if my_index.nil?
    return self.issue.ordered_articles[my_index+1]
  end

  # mapping do
  #   indexes :id, type: 'integer'
  #   indexes :title
  #   indexes :teaser
  #   indexes :category
  #   indexes :author
  #   indexes :body
  #   indexes :featured_image_caption
  #   indexes :publication, type: 'date'
  #   indexes :published, type: 'boolean', as: 'published'
  # end

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

  def first_image
    image = self.images.order("position").first
    if not image.blank?
      return image
    else
      return nil
    end
  end

  def is_a_feature
    if self.categories.select {|c| c.name == '/features/'}.count > 0
      return true
    else
      return false
    end
  end

  def has_category(category_name)
    if self.categories.select {|c| c.name == category_name}.count > 0
      return true
    else
      return false
    end
  end

  def published
    # issue.published and not unpublished
    (not unpublished) and issue.published
  end

  def self.published_articles
    all_published_articles = []
    Article.find_each do |a|
      if a.published
        all_published_articles << a
      end
    end
    all_published_articles
  end

  # Guest pass checking
  def is_valid_guest_pass(key)
    if key
      pass = self.guest_passes.where(:key => key).first
      if pass
        pass.last_used = DateTime.now
        pass.use_count += 1
        pass.save
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def self.quick_reads
    Rails.cache.fetch("quick_reads", expires_in: 24.hours) do
      # Need .to_a here otherwise it caches the scope, not the result of the query
      self.published_articles.sample(3).sort_by{|a| a.publication}.reverse.to_a
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

  protected

    def category_exists(category_attributes)
      if _category = Category.find_by_name(category_attributes['name'])
        self.categories << _category unless self.categories.include?(_category)
        return true
      end
      return false
    end

end
