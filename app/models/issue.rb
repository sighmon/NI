class Issue < ActiveRecord::Base
  attr_accessible :number, :release, :title, :trialissue, :cover, :editors_letter, :editors_name, :editors_photo, :published
  has_many :articles, :dependent => :destroy
  has_many :purchases
  has_many :users, :through => :purchases
  mount_uploader :cover, CoverUploader
  mount_uploader :editors_photo, EditorsPhotoUploader
  # If versions need reprocssing
  # after_update :reprocess_image

  include Tire::Model::Search
  include Tire::Model::Callbacks

  # Index name for Heroku Bonzai/elasticsearch
  index_name BONSAI_INDEX_NAME

  # Not over-riding this anymore as it breaks kaminari-bootstrap styling
  # def self.search(params)
  #   tire.search(load: true) do
  #     query { string params[:query]} if params[:query].present?
  #   end
  # end

  def self.search(params, unpublished = false)
    tire.search(load: true, :page => params[:page], :per_page => Settings.issue_pagination) do
      query {string params[:query]} if params[:query].present?
      filter :term, :published => true unless unpublished
      sort { by :release, 'desc' }
    end
  end

  # if params[:query].present?
    #     @issues = Issue.search(load: true, :page => params[:page], :per_page => Settings.issue_pagination) do
    #       query { string(params[:query]) }
    #     end
    # else
    #     @issues = Issue.order("release").reverse_order.page(params[:page]).per(Settings.issue_pagination)
    # end

  def price
    return Settings.issue_price
  end

  # Setting up SOAP to import articles from Bricolage using Savon
  def import_articles_from_bricolage()
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
    # print response.http.cookies
    # Create primary_uri to search for based on Issue.release date
    primary_uri = "%%/%s/%%" % release.strftime("%Y/%m/%d")
    response = client.request "story", "story_ids" do
      http.headers["SOAPAction"] = "\"http://bricolage.sourceforge.net/Bric/SOAP/Story#list_ids\""
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
    <list_ids xmlns="http://bricolage.sourceforge.net/Bric/SOAP/Story">
      <primary_uri xsi:type="xsd:string">%s</primary_uri>
    </list_ids>
  </soap:Body>
</soap:Envelope>' % primary_uri
    end
    # print response.to_json
    # Pull the story_ids from the search results element passed from SOAP
    story_ids = response[:list_ids_response][:story_ids][:story_id]
    # Handle a blank response or one result
    if story_ids.blank? or story_ids.nil?
      story_ids = []
    elsif story_ids.is_a? Array
    else
      story_ids = Array.new << story_ids
    end
    story_id_block = story_ids.collect{|id| '<story_id xsi:type="xsd:int">%s</story_id>' % id}.join("\n")
    response = client.request "story", "story_ids" do
      http.headers["SOAPAction"] = "\"http://bricolage.sourceforge.net/Bric/SOAP/Story#export\""
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
    <export xmlns="http://bricolage.sourceforge.net/Bric/SOAP/Story">
      <story_ids soapenc:arrayType="xsd:int[%d]" xsi:type="soapenc:Array">
        %s
      </story_ids>
    </export>
  </soap:Body>
</soap:Envelope>' % [story_ids.length, story_id_block]
    end
    doc = Nokogiri::XML(Base64.decode64(response[:export_response][:document]).force_encoding("UTF-8"))
    stories = doc.xpath("//assets:story",'assets' => 'http://bricolage.sourceforge.net/assets.xsd')
    #return stories
    stories.collect do |element|
      a = Article.create_from_element(self,element)
    end
    stories
  end

  def articles_of_category(category_name)
    arts = self.articles.select{|a| not a.keynote}
    g = []
    arts.each do |article|
      if not article.categories.select{|c| c.name.include?(category_name)}.empty?
        g << article
      end
    end
    return g
  end

  def all_category_names
    n = []
    self.articles.each do |article|
      article.categories.each do |category|
        if not category.name.include?("/themes/")
          n << category.name
        end
      end
    end
    return n
  end

  private

  def reprocess_image
    cover.recreate_versions!
    editors_photo.recreate_versions!
  end

end
