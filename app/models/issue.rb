class Issue < ActiveRecord::Base
  attr_accessible :number, :release, :title, :trialissue, :cover, :editors_letter, :editors_name, :editors_photo, :published, :email_text, :zip
  has_many :articles, :dependent => :destroy
  has_many :purchases
  has_many :users, :through => :purchases
  mount_uploader :cover, CoverUploader
  mount_uploader :editors_photo, EditorsPhotoUploader
  mount_uploader :zip, ZipUploader
  # If versions need reprocssing
  # after_update :reprocess_image

  after_commit :flush_cache

  include Tire::Model::Search
  include Tire::Model::Callbacks

  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::NumberHelper

  # For zipruby
  require 'zipruby'

  # Need to include the helper so we can call source_to_body for the zip file
  include ArticlesHelper

  # Including ApplicationHelper for cents_to_dollars
  include ApplicationHelper

  # Index name for Heroku Bonzai/elasticsearch
  index_name BONSAI_INDEX_NAME

  # Not over-riding this anymore as it breaks kaminari-bootstrap styling
  # def self.search(params)
  #   tire.search(load: true) do
  #     query { string params[:query]} if params[:query].present?
  #   end
  # end

  def self.search(params, admin = false)
    pagination = Settings.issue_pagination
    if admin
      pagination = 200
    end
    tire.search(load: true, :page => params[:page], :per_page => pagination) do
      query {string params[:query], default_operator: "AND"} if params[:query].present?
      filter :term, :published => true unless admin
      sort { by :release, 'desc' }
    end
  end

  def self.latest
    Issue.all.sort_by{|i| i.release}.last
  end
    
 
  def gift_to_subscribers
    User.all.select{|u| u.subscriber?}.each{|u| self.gift_to_user(u)}
  end
 
  def gift_to_user(user)
    if user.purchases.where(issue_id:self.id).blank?
      purchase = Purchase.create(user_id: user.id, issue_id: self.id)
    end
  end

  def keynote
    Issue.cached_keynote_for_issue(self)
  end

  def self.cached_keynote_for_issue(id)
    Rails.cache.fetch([name, id]) { find(id).articles.find_by_keynote(true) }
  end

  def flush_cache
    Rails.cache.delete([self.class.name, id])
  end

  def features
    articles_of_category("/features/").sort_by(&:publication)
  end

  def agendas
    articles_of_category("/sections/agenda/").sort_by(&:publication)
  end

  def currents
    articles_of_category("/columns/currents/").sort_by(&:publication)
  end

  def opinion
    (articles_of_category("/argument/") +
      articles_of_category("/columns/viewfrom/") +
      articles_of_category("/columns/mark-engler/") +
      articles_of_category("/columns/steve-parry/") + 
      articles_of_category("/columns/kate-smurthwaite/")
      ).sort_by(&:publication)
  end

  def alternatives
    articles_of_category("/alternatives/").sort_by(&:publication)
  end

  def regulars
    (articles_of_category("/columns/") - 
      articles_of_category("/columns/currents/") - 
      articles_of_category("/columns/media/") - 
      articles_of_category("/columns/viewfrom/") - 
      articles_of_category("/columns/mark-engler/") -
      articles_of_category("/columns/steve-parry/") - 
      articles_of_category("/columns/kate-smurthwaite/")
      ).sort_by(&:publication)
  end

  def mixedmedia
    articles_of_category("/columns/media/").sort_by(&:publication)
  end

  def blogs
    articles_of_category("/blog/").sort_by(&:publication)
  end

  def categorised_articles
    features + agendas + currents + opinion + regulars + alternatives + mixedmedia + blogs
  end

  def uncategorised
    articles - categorised_articles - [keynote]
  end

  def ordered_articles
    [self.keynote] + self.categorised_articles
  end

  def editors_letter_html
    ed = simple_format(self.editors_letter)
    ed = ed.gsub(/\n/, "")
    ed = ed.gsub(/(\")/, "'")
    ed = ed.gsub(/<p><h(\d)>/,"<h\\1>")
    ed = ed.gsub(/<\/h(\d)><\/p>/,"</h\\1>")
    return ed
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
  def self.bricolage_wrapper()
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
    client.http.set_cookies(response.http)
    yield client
  end
  
  def import_articles_from_bricolage()

    Issue.bricolage_wrapper do |client|
      # print response.http.cookies
      # Create primary_uri to search for based on Issue.release date
      primary_uri = "%%/%s/%%" % release.strftime("%Y/%m/%d")
      response = client.request "story", "story_ids" do
        http.headers["SOAPAction"] = "\"http://bricolage.sourceforge.net/Bric/SOAP/Story#list_ids\""
        #http.set_cookies(response.http)
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
        # do nothing
      else
        story_ids = Array.new << story_ids
      end
   
      # filter story_ids with articles in the database
      story_ids.select!{|id|Article.find_by_story_id(id.to_s).nil?}

      self.import_stories_from_bricolage(story_ids)
    end
  end

  def create_article_from_element(element)
    assets = 'http://bricolage.sourceforge.net/assets.xsd'
    story_id = element[:id].to_i
    # TODO: Allow for posibility that issue is nil.
    a = self.articles.find_or_create_by_story_id(story_id)
    a.update_attributes(
      :title => element.at_xpath("./assets:name",'assets' => assets ).try(:text),
      :teaser => element.at_xpath('./assets:elements/assets:field[@type="teaser"]','assets' => assets).try(:text).try(:gsub,/\n/, " "),
      :author => element.xpath('./assets:contributors/assets:contributor','assets'=>assets).collect{|n| ['fname','mname','lname'].collect{|t| n.at_xpath("./assets:#{t}",'assets'=>assets).try(:text) }.select{|n|!n.empty?}.join(" ")}.join(","),
      :publication => DateTime.parse(element.at_xpath('./assets:cover_date','assets'=>assets).try(:text) ),
      :source => element.to_xml
    )
    category_list = element.xpath(".//assets:category",'assets' => assets)
    category_list.collect do |cat|
      c = Category.create_from_element(a,cat)
    end
    return a
  end

  def import_stories_from_bricolage(story_ids)

    Issue.bricolage_wrapper do |client|
      story_id_block = story_ids.collect{|id| '<story_id xsi:type="xsd:int">%s</story_id>' % id}.join("\n")

      response = client.request "story", "story_ids" do
        http.headers["SOAPAction"] = "\"http://bricolage.sourceforge.net/Bric/SOAP/Story#export\""
        #http.set_cookies(response.http)
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
        a = self.create_article_from_element(element)
      end
      stories
    end
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

  def zip_for_ios
    # Zip file structure
    # issueID
    # {
    #   issue.json
    #   number_cover.png
    #   editor_name.jpg
    #   {
    #     articleID 
    #     {
    #       article.json
    #       body.html
    #       imageID.png
    #     }
    #   }
    # }

    zip_file_path = "#{Rails.root}/tmp/#{self.id}.zip"
    issue_json_file_location = "#{Rails.root}/tmp/#{self.id}.json"

    # Create temporary file for issue.json
    File.open(issue_json_file_location, "w"){ |f| f << Issue.issues_index_to_json(self)}
    
    # Make zip file
    Zip::Archive.open(zip_file_path, Zip::CREATE) do |zipfile|

      if Rails.env.production?
        cover_to_add = open(self.cover.png.to_s)
        editors_photo_to_add = open(self.editors_photo_url)
      else
        cover_to_add = open(self.cover.png.path)
        editors_photo_to_add = open(self.editors_photo.path)
      end
      zipfile.add_buffer(File.basename(self.cover.png.to_s), cover_to_add.read)
      zipfile.add_buffer(File.basename(self.editors_photo.to_s), editors_photo_to_add.read)

      zipfile.add_file("issue.json", issue_json_file_location)

      # Loop through articles
      self.articles.find_each do |a|        
        # Create temporary file for issue_id.json
        File.open(article_json_file_location(a.id), "w"){ |f| f << a.to_json(Issue.article_information_to_include_in_json_hash) }

        # Add the article body
        if a.body and not a.body.empty?
          body_to_zip = simple_format(a.body)
        else
          body_to_zip = simple_format(source_to_body(a, :debug => false))
        end

        # Add the css for iOS
        body_to_zip = '<div class="article-body"><p>' + body_to_zip + "</p></div>"

        File.open(article_body_file_location(a.id), "w"){ |f| f << body_to_zip }

        # Add article.json to article_id directory
        zipfile.add_dir(a.id.to_s)
        zipfile.add_file("#{a.id}/article.json", article_json_file_location(a.id))

        # Add body.html
        zipfile.add_file("#{a.id}/body.html", article_body_file_location(a.id))

        # Add featured image
        if a.featured_image.to_s != ""
          if Rails.env.production?
            featured_image_to_add = open(a.featured_image_url)
          else
            featured_image_to_add = open(a.featured_image.path)
          end
          zipfile.add_buffer("#{a.id}/#{File.basename(a.featured_image.to_s)}", featured_image_to_add.read)
        end

        # Loop through the images
        a.images.find_each do |i|
          if Rails.env.production?
            # Do article images need to be pngs?
            # No, we want to transfer smallest files possible - make PNGs on the iOS side.
            image_to_add = open(i.data_url)
          else
            image_to_add = open(i.data.path)
          end
          zipfile.add_buffer("#{a.id}/#{File.basename(i.data.to_s)}", image_to_add.read)
        end
      end
    end

    # Send zip file
    File.open(zip_file_path, 'r') do |f|
      # Uncomment to download the zip file for checking locally also
      # send_data f.read, :type => "application/zip", :filename => "#{self.id}.zip", :x_sendfile => true
      # Upload with carrierwave ZipUploader
      self.zip = f
      self.save
    end

    # Delete the zip & tmp files.
    File.delete(zip_file_path)
    File.delete(issue_json_file_location)
    self.articles.each do |a|
      File.delete(article_json_file_location(a.id))
      File.delete(article_body_file_location(a.id))
    end
  end

  def article_json_file_location(article_id)
    "#{Rails.root}/tmp/article#{article_id}.json"
  end

  def article_body_file_location(article_id)
    "#{Rails.root}/tmp/article#{article_id}.html"
  end

  def self.issues_index_to_json(issues)
    issues.to_json(
      # Q: do we need :editors_letter here? it can be quite large.
      :only => [:title, :id, :number, :editors_name, :editors_photo, :release, :cover],
      :methods => [:editors_letter_html]
    )
  end

  def self.article_information_to_include_in_json_hash
    { 
      :only => [:title, :teaser, :keynote, :featured_image, :featured_image_caption, :id, :publication],
      :include => {
        :images => {},
        :categories => { :only => [:name, :colour, :id] }
      }
    }
  end

  def google_play_inapp_id
    number.to_s + 'single'
  end

  def google_play_published
    if published
      'published'
    else
      'unpublished'
    end
  end

  def google_play_purchase_type
    'managed_by_android'
  end

  def google_play_autotranslate
    # Apparently this feature isn't supported by Google Play anymore
    # true
    false
  end

  def google_play_locale_title_description
    'en_GB' + ';' + title + ';' + truncate((keynote ? strip_tags(keynote.teaser) : "The #{release.strftime("%B %Y")} issue of New Internationalist magazine."), length: 80)
  end

  def google_play_autofill
    true
  end

  def google_play_country_price
    # 'AU' + ';' + (price * 1000).to_s
    cents_to_dollars(price)
  end

  # CSV exporting for Google Play in-app purchases
  # "product_id","publish_state","purchase_type","autotranslate ","locale; title; description","autofill","country; price"
  comma do

    google_play_inapp_id 'product_id'
    google_play_published 'publish_state'
    google_play_purchase_type 'purchase_type'
    google_play_autotranslate 'autotranslate'
    google_play_locale_title_description 'locale; title; description'
    google_play_autofill 'autofill'
    google_play_country_price 'country; price'

  end

  private

  def reprocess_image
    cover.recreate_versions!
    editors_photo.recreate_versions!
  end

end
