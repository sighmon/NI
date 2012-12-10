class Article < ActiveRecord::Base
  belongs_to :issue
  attr_accessible :author, :body, :publication, :teaser, :title, :trialarticle, :keynote, :source, :featured_image, :featured_image_caption
  mount_uploader :featured_image, FeaturedImageUploader

  # join-model for favourites
  has_many :favourites
  has_many :users, :through => :favourites

  has_many :images

  include Tire::Model::Search
  include Tire::Model::Callbacks

  # Index name for Heroku Bonzai/elasticsearch
  index_name BONSAI_INDEX_NAME

  def self.create_from_element(issue,element)
    assets = 'http://bricolage.sourceforge.net/assets.xsd'
    return issue.articles.create(
      :title => element.at_xpath("./assets:name",'assets' => assets ).try(:text),
      :teaser => element.at_xpath('./assets:elements/assets:field[@type="teaser"]','assets' => assets).try(:text),
      :author => element.xpath('./assets:contributors/assets:contributor','assets'=>assets).collect{|n| ['fname','mname','lname'].collect{|t| n.at_xpath("./assets:#{t}",'assets'=>assets).try(:text) }.select{|n|!n.empty?}.join(" ")}.join(","),
      :publication => DateTime.parse(element.at_xpath('./assets:cover_date','assets'=>assets).try(:text) ),
      # :body => Hash.from_xml(element.to_xml).to_json
      :source => element.to_xml
    )
  end

  def source_to_body(options = {})
    debug = options[:debug] or false
    if not self.source.blank?
      if self.body.blank?
        
        doc = Nokogiri::XML(self.source)

        def process_children(e, debug = false)
          e.xpath("*").sort_by{|n| n["order"].to_i}.collect{|e| process_element(e,debug)}.join("")
        end

	      def process_element(e, debug = false)
          if e.name == "container"
            if e["element_type"] == "cross_head"
              "<h3>"+process_children(e, debug)+"</h3>"
            elsif e["element_type"] == "cross_head_2"
              "<h4>"+process_children(e, debug)+"</h4>"
            elsif e["element_type"] == "pull_quote"
              alignment = e.at_xpath("field[@type='alignment']").text 
              "<blockquote class='pull-#{alignment}'>"+process_children(e, debug)+"</blockquote>"
            elsif e["element_type"] == "box"
              "<div class='box'>"+process_children(e,debug)+"</div>"
            elsif e["element_type"] == "author_note"
              "<div class='author-note'>"+process_children(e,debug)+"</div>"
            elsif e["element_type"] == "related_media"
              media_id = e["related_media_id"]
              media_url = Image.find_by_media_id(media_id).try(:data_url, :halfwidth)
              alignment = e.at_xpath("field[@type='alignment']").text 
              "<div class='article-image' style='float: #{alignment}'><img src='#{media_url}'/>"+process_children(e,debug)+"</div>"
            elsif e["element_type"] == "footnotes"
              "<ol class='footnotes'>"+process_children(e,debug)+"</ol>"
            elsif ["page_no"].include? e["element_type"]
              #ignore
            else
              "[UNKNOWN_CONTAINER{type="+e["element_type"]+"}: "+process_children(e,debug)+" /CONTAINER]" if debug
            end
          elsif e.name == "field"
            if ["paragraph","quote","an_author_note"].include? e["type"]
              # paragraph-like things
              "<p>#{e.text.gsub(/\n/, " ")}</p>"
            elsif e["type"] == "rel_media_caption"
              "<div class='new-image-caption'>#{e.text.gsub(/\n/, " ")}</div>"
            elsif e["type"] == "rel_media_credit"
              "<div class='new-image-credit'>#{e.text}</div>"
            elsif e["type"] == "cross_head"
              e.text
            elsif e["type"] == "cross_head_2"
              e.text
            elsif e["type"] == "foot_ref"
              "<li>#{e.text.gsub(/\n/, " ")}</li>"
            elsif e["type"] == "box_title"
              "<h4>#{e.text}</h4>"
            elsif ["issue_number","teaser","deck","page_no","alignment","hold","rel_media_class"].include? e["type"]
              #ignore 
            else
              "[unknown field type "+e["type"]+"]" if debug
            end
          else
            "[unknown tag #{e.name}]" if debug
          end 
        end

        self.body = process_children(doc.xpath("//story/elements"),debug).html_safe

      end
    end
  end

  def extract_media_ids_from_source
    return Nokogiri::XML(self.source).xpath('//container[@element_type="related_media"]').collect{|e| e["related_media_id"]}
  end

  # TODO: make private
  # private

  def import_media_from_bricolage(media_ids = self.extract_media_ids_from_source)
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

end
