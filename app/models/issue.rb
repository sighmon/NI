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
    HTTPI.log_level = :debug
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
    print response.http.cookies
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
              <story_ids soapenc:arrayType="xsd:int[1]" xsi:type="soapenc:Array">
                <story_id xsi:type="xsd:int">19238</story_id>
              </story_ids>
            </export>
          </soap:Body>
        </soap:Envelope>'
    end
    print response.to_json
  end

  private

  def reprocess_image
    cover.recreate_versions!
    editors_photo.recreate_versions!
  end

end
