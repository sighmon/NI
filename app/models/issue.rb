class Issue < ActiveRecord::Base
  attr_accessible :number, :release, :title, :trialissue, :cover, :editors_letter, :editors_name, :editors_photo
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
      <primary_uri xsi:type="xsd:string">%/2012/10/01/%</primary_uri>
    </list_ids>
  </soap:Body>
</soap:Envelope>'
    end
    #print response.to_json
    story_ids = response[:list_ids_response][:story_ids][:story_id]
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
      <story_ids soapenc:arrayType="xsd:int[12]" xsi:type="soapenc:Array">
        <story_id xsi:type="xsd:int">19234</story_id>
        <story_id xsi:type="xsd:int">19236</story_id>
        <story_id xsi:type="xsd:int">19238</story_id>
        <story_id xsi:type="xsd:int">19239</story_id>
        <story_id xsi:type="xsd:int">19241</story_id>
        <story_id xsi:type="xsd:int">19242</story_id>
        <story_id xsi:type="xsd:int">19244</story_id>
        <story_id xsi:type="xsd:int">19245</story_id>
        <story_id xsi:type="xsd:int">19246</story_id>
        <story_id xsi:type="xsd:int">19248</story_id>
        <story_id xsi:type="xsd:int">19251</story_id>
        <story_id xsi:type="xsd:int">19253</story_id>
      </story_ids>
    </export>
  </soap:Body>
</soap:Envelope>'
    end
    doc = Nokogiri::XML(Base64.decode64(response[:export_response][:document]).encode())
    doc.xpath("//assets:story",'assets' => 'http://bricolage.sourceforge.net/assets.xsd').collect do |element|
      a = Article.create_from_element(element)
      a.save
    end
  end

  private

  def reprocess_image
    cover.recreate_versions!
    editors_photo.recreate_versions!
  end

end
