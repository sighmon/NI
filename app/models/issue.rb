class Issue < ActiveRecord::Base
  
  has_many :articles, -> { where(unpublished: [false, nil]) }, :dependent => :destroy
  has_many :all_articles, :class_name => "Article"
  has_many :purchases
  has_many :users, :through => :purchases
  mount_uploader :cover, CoverUploader
  mount_uploader :editors_photo, EditorsPhotoUploader
  mount_uploader :zip, ZipUploader
  # If versions need reprocssing
  # after_update :reprocess_image

  after_commit :flush_cache

  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  include ActionView::Helpers::TextHelper

  # For zipruby
  require 'zipruby'

  # Need to include the helper so we can call source_to_body for the zip file
  include ArticlesHelper

  # Index name for Heroku Bonzai/elasticsearch
  index_name BONSAI_INDEX_NAME

  def self.search(params, admin = false)
    pagination = Settings.issue_pagination
    if admin
      pagination = 200
    end
    search_hash = {
      sort: [{ release: {order: "desc"}}]
    }
    search_hash.merge!({query: { query_string: { query: params[:query], default_operator: "AND" }}}) if params[:query].present?
    search_hash.merge!({ post_filter: { term: { published: true}} }) unless admin

    __elasticsearch__.search(search_hash).page(params[:page]).per(pagination).records
  end

  def self.latest
    Issue.where(published: true).order(:release).last
  end

  def self.latest_free
    Issue.select{|issue| issue.trialissue and not issue.digital_exclusive}.first
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
    Issue.cached_keynote_for_issue(self.id)
  end

  def self.cached_keynote_for_issue(id)
    Rails.cache.fetch([name, id]) { find(id).articles.find_by_keynote(true) }
  end

  def flush_cache
    Rails.cache.delete([self.class.name, id])
  end

  def features
    (articles_of_category("/features/") -
      articles_of_category("/features/web-exclusive/")
      ).sort_by(&:publication)
  end

  def web_exclusive
    (articles_of_category("/features/web-exclusive/") -
      articles_of_category("/video/")
      ).sort_by(&:publication)
  end

  def videos
    articles_of_category("/video/").sort_by(&:publication)
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
      articles_of_category("/columns/kate-smurthwaite/") + 
      articles_of_category("/columns/chris-coltrane/")
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
      articles_of_category("/columns/kate-smurthwaite/") -
      articles_of_category("/columns/chris-coltrane/") -
      articles_of_category("/video/")
      ).sort_by(&:publication)
  end

  def mixedmedia
    articles_of_category("/columns/media/").sort_by(&:publication)
  end

  def blogs
    (articles_of_category("/blog/") -
      articles_of_category("/features/")
      ).sort_by(&:publication)
  end

  def categorised_articles
    features + web_exclusive + videos + agendas + currents + opinion + regulars + alternatives + mixedmedia + blogs
  end

  def uncategorised
    all_articles - categorised_articles - [keynote]
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

  # Import articles from the new newint.org server
  def import_articles_from_newint_org(options = {})

    # Optional: hand in issue number {issue_number: xxx}
    # Optional: mark articles as unpublished? options[:unpublished]
    # Optional: hand in a specific article URL {article_url: xxx}
    issue_number_to_import = self.number
    article_url_to_import = nil
    force_reimport_all = false
    if not options.nil?
      if options[:issue_number]
        issue_number_to_import = options[:issue_number]
      end
      article_url_to_import = options[:article_url]
      force_reimport_all = options[:force]
    else
      options = {}
    end

    xcsfr_token = csrf_token_from_newint_org

    if xcsfr_token
      # Import issue details
      response_from_newint_org = request_json_from_newint_org(ENV["NEWINT_ORG_REST_ISSUE_URL"] + issue_number_to_import.to_s, xcsfr_token)
      
      if response_from_newint_org
        # Request the articles using the issue tid.
        issue_tid = JSON.parse(response_from_newint_org)["list"].first["tid"]
        articles_response_from_newint_org = request_json_from_newint_org(ENV["NEWINT_ORG_REST_ARTICLES_URL"] + issue_tid.to_s, xcsfr_token)
        # TODO: Alternatively only request the article by URL.
        if articles_response_from_newint_org
          # Articles from this issue
          articles_json_from_newint_org = JSON.parse(articles_response_from_newint_org)["list"]
          articles_json_from_newint_org.each do |a|
            # Create article from json only if article_url_to_import is nil, or matches the url
            if article_url_to_import.nil? or article_url_to_import == a["url"]
              # byebug
              article_created = create_article_from_newint_org_json(a, xcsfr_token, options)
            end
          end

          # return articles_json_from_newint_org
          return true
        else
          # Bad articles response
          logger.warn "ARTICLES REQUEST FAILED."
          return nil
        end
        
        logger.info "Finished getting articles."
        return "Success!"
      else
        logger.warn "CHECK RESPONSE FROM NEWINT.ORG!"
        return nil
      end
    else
      logger.info "NO VALID TOKEN. :-("
      return nil
    end

  end

  def create_article_from_newint_org_json(article_json, token, options)
    force_reimport_all = false
    if not options.nil?
      force_reimport_all = options[:force]
    else
      options = {}
    end
    article_created = self.articles.where(story_id: article_json["nid"]).first_or_create
    
    if (article_created.title == nil) or (force_reimport_all == true)
      # It doesn't already exist, so import
      
      article_created.update_attributes(
        title: article_json["title"],
        teaser: (article_json["field_deck"].try(:[],"value").try(:gsub,/\n/, " ").try(:gsub,/<p>/, "").try(:gsub,/<\/p>/, "") unless article_json["field_deck"].empty?),
        publication: Time.at(article_json["created"].to_i).to_datetime,
        body: (article_json["body"]["value"].try(:gsub,/\n/, " ") unless article_json["body"].empty?),
        unpublished: options[:unpublished]
      )

      # Request contributor information.
      if article_json["field_contributor"]
        article_info_response_from_newint_org = request_json_from_newint_org(ENV["NEWINT_ORG_REST_TAXONOMY_TERM_URL"] + article_json["field_contributor"].first.try(:[],"id").to_s + ".json", token)  
      end
      
      if article_info_response_from_newint_org
        article_info_json_from_newint_org = JSON.parse(article_info_response_from_newint_org)
        # Write name to article: article_info_json_from_newint_org["name"]
        article_created.update_attributes(
          author: article_info_json_from_newint_org["name"],
        )
      end

      # Request categories tags and themes.
      article_json_tags = []
      if article_json["field_tags"] and not article_json["field_tags"].empty?
        article_json_tags += article_json["field_tags"]
      end
      if article_json["field_themes"] and not article_json["field_themes"].empty?
        article_json_tags += article_json["field_themes"]
      end
      if not article_json_tags.empty?
        article_json_tags.each do |cat|
          article_category_response_from_newint_org = request_json_from_newint_org(ENV["NEWINT_ORG_REST_TAXONOMY_TERM_URL"] + cat["id"].to_s + ".json", token)
          if article_category_response_from_newint_org
            article_category_json_from_newint_org = JSON.parse(article_category_response_from_newint_org)
            # Find/create category and add it to article.
            Category.create_from_element(article_created, article_category_json_from_newint_org["name"].try(:titlecase))
          end
        end
      end

      # Request image information.
      if article_json["field_image"] and not article_json["field_image"].empty?
        article_image_response_from_newint_org = request_json_from_newint_org(article_json["field_image"]["file"]["uri"].to_s + ".json", token)
        if article_image_response_from_newint_org
          article_image_json_from_newint_org = JSON.parse(article_image_response_from_newint_org)
          # Find or create image and add it to article
          header_image_created = Image.create_from_uri(article_created, article_image_json_from_newint_org["url"].to_s, {alt: article_json["field_image"]["alt"], media_id: article_json["field_image"]["file"]["id"]})
          # Embed new File code to article body
          if header_image_created
            image_file_code = "[File:#{header_image_created.id}|full]"
            if not article_created.body.include?(image_file_code)
              article_created.body.prepend(image_file_code)
              article_created.save
            end
          end
        else
          logger.warn "IMAGE REQUEST FAILED for #{article_json["field_image"]["file"]["uri"].to_s}"
        end
      end

      # Pull out embedded images and create them in the db
      article_html = Nokogiri::HTML.fragment(article_created.body)
      image_fragments = article_html.css('img')
      image_fragments.each do |img|
        image_uri = "https://" + URI.parse(ENV["NEWINT_ORG_REST_TOKEN_URL"]).host + img["src"]
        image_created = Image.create_from_uri(article_created, image_uri, {alt: img["alt"]})
        if image_created
          image_file_code = "[File:#{image_created.id}]"
          # Remove the img HTML from the article_created.body and replace with [File:xxx]
          # Hack: Nokogiri parses out the trailing <img /> slash, so to find it I have to use brittle regex
          article_created.body = article_created.body.sub(/#{img.to_html[0...-1]}(.*?)>/, image_file_code)
          article_created.save
        end

      end

    else
      # It's already imported, so don't overwrite.

    end
    
    return article_created
  end

  def request_json_from_newint_org(url, token)
    request = HTTPI::Request.new
    request.url = url
    request.headers = { "Accept": "application/json", "X-CSRF-Token": token }
    request.auth.basic(ENV["NEWINT_ORG_REST_USERNAME"], ENV["NEWINT_ORG_REST_PASSWORD"])
    response_from_newint_org = HTTPI.get(request)
    logger.info "Request to: #{url}"
    logger.info "Response: #{response_from_newint_org.code.to_s}"
    response_body = nil
    if response_from_newint_org.code >= 200 and response_from_newint_org.code < 300
      # Good response
      response_body = response_from_newint_org.body
    else
      logger.warn "Error! Headers: #{response_from_newint_org.headers}"
      logger.warn "Error! Body: #{response_from_newint_org.body}"
    end
    return response_body
  end

  def csrf_token_from_newint_org
    # First get a token
    request = HTTPI::Request.new
    request.url = ENV["NEWINT_ORG_REST_TOKEN_URL"]
    request.headers = { "Content-type": "text/plain" }
    request.auth.basic(ENV["NEWINT_ORG_REST_USERNAME"], ENV["NEWINT_ORG_REST_PASSWORD"])
    response = HTTPI.get(request)
    # byebug
    logger.info "TOKEN RESPONSE: " + response.code.to_s
    # logger.info response.headers

    xcsfr_token = nil
    if response.code >= 200 and response.code < 300
      # Token has arrived
      xcsfr_token = response.body
    end
    return xcsfr_token
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
  
  def import_articles_from_bricolage(options = {})

    # Handling the case where this is called handing in nil
    if not options.nil?
      special_type = options[:special_type]
      # custom uri format: "%/blog/2016/05/%"
      custom_uri = options[:custom_uri]
    else
      options = {}
    end

    Issue.bricolage_wrapper do |client|
      # print response.http.cookies
      # Create primary_uri to search for based on Issue.release date
      if custom_uri and not custom_uri.blank?
        primary_uri = custom_uri
      elsif special_type and not special_type.blank?
        primary_uri = "%%/#{special_type}/%s/%%" % release.strftime("%Y/%m")
      else
        primary_uri = "%%/%s/%%" % release.strftime("%Y/%m/%d")
      end
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
      self.import_stories_from_bricolage(story_ids, options)
    end
  end

  def create_article_from_bricolage_element(element, options)
    assets = 'http://bricolage.sourceforge.net/assets.xsd'
    story_id = element[:id].to_i
    # TODO: Allow for posibility that issue is nil.
    a = self.articles.where(story_id: story_id).first_or_create
    a.update_attributes(
      :title => element.at_xpath("./assets:name",'assets' => assets ).try(:text),
      :teaser => element.at_xpath('./assets:elements/assets:field[@type="teaser"]','assets' => assets).try(:text).try(:gsub,/\n/, " "),
      :author => element.xpath('./assets:contributors/assets:contributor','assets'=>assets).collect{|n| ['fname','mname','lname'].collect{|t| n.at_xpath("./assets:#{t}",'assets'=>assets).try(:text) }.select{|n|!n.empty?}.join(" ")}.join(","),
      :publication => DateTime.parse(element.at_xpath('./assets:cover_date','assets'=>assets).try(:text) ),
      :source => element.to_xml,
      :unpublished => options[:unpublished]
    )
    category_list = element.xpath(".//assets:category",'assets' => assets)
    category_list.collect do |cat|
      c = Category.create_from_element(a,cat.try(:text))
    end
    return a
  end

  def import_stories_from_bricolage(story_ids, options)

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
        a = self.create_article_from_bricolage_element(element, options)
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

  def all_articles_categories
    Rails.cache.fetch("#{cache_key}/all_articles_categories", expires_in: 12.hours) do
      categories = []
      self.articles.each do |article|
        categories = categories | article.categories
      end
      categories.sort_by(&:short_display_name)
    end
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

  def apple_news_json
    editors_letter = ActionController::Base.helpers.strip_tags(self.editors_letter).gsub("\r\n\r\n", "\n\n")
    apple_news_hash = {
      title: self.title,
      subtitle: ActionController::Base.helpers.truncate(editors_letter, :length => 100),
      metadata: {
        thumbnailURL: self.cover_url(:home2x).to_s,
        excerpt: ActionController::Base.helpers.truncate(editors_letter, :length => 100),
        canonicalURL: Rails.application.routes.url_helpers.issue_url(self),
        datePublished: self.release.to_datetime.iso8601,
        dateModified: self.release.to_datetime.iso8601,
        dateCreated: self.release.to_datetime.iso8601,
        # coverArt: {
        #   type: "image",
        #   URL: self.cover_url(:home2x).to_s,
        #   accessibilityCaption: self.title
        # },
        keywords: ["new", "internationalist", "magazine", "archive", "digital", "edition", "australia"],
        authors: [self.editors_name]
      },
      version: "1.2",
      identifier: ENV["APPLE_NEWS_IDENTIFIER"],
      language: "en",
      layout: {
        columns: 10,
        width: 1024,
        margin: 85,
        gutter: 20
      },
      documentStyle: {
        backgroundColor: "#F5F9FB"
      },
      # "textStyles": {},
      "componentLayouts": {
        "default-divider": {
          "margin": {
            "top": 10,
            "bottom": 20
          },
          "stroke": {
            color: "#DBDBDB",
            width: 2
          }
        },
        "default-image": {
          "maximumContentWidth": 200,
          "margin": {
            "top": 10
          }
        },
        "default-title": {
          "margin": {
            "top": 20,
            "bottom": 5
          }
        },
        "default-intro": {
          "margin": {
            "bottom": 15
          }
        },
        "default-byline": {
          "margin": {
            "bottom": 10
          }
        },
        "default-body": {
          "margin": {
            "bottom": 20
          }
        },
        "article-photo": {
          "ignoreDocumentGutter": "both",
          "ignoreDocumentMargin": "both",
          "margin": 0,
          "gutter": 0
        },
        "article-title": {
          "margin": {
            "top": 20,
            "bottom": 5
          }
        },
        "article-byline": {
          "margin": {
            "bottom": 10
          }
        }
      },
      "componentStyles": {},
      "componentTextStyles": {
        "default-title": {
          "fontName": "AppleSDGothicNeo-Bold",
          "textColor": "#000000",
          "fontSize": 38,
          "stroke": {
            "color": "#000000",
            "width": 2
          }
        },
        "default-byline": {
          "fontName": "AppleSDGothicNeo-Medium",
          "textColor": "#999999",
          "fontSize": 18
        },
        "default-intro": {
          "fontName": "AppleSDGothicNeo-Medium",
          "textColor": "#999999",
          "fontSize": 14
        },
        "default-body": {
          "textColor": "#333333"
        },
        "article-title": {
          "fontName": "AppleSDGothicNeo-Bold",
          "textColor": "#000000",
          "fontSize": 20,
          "stroke": {
            "color": "#000000",
            "width": 2
          }
        },
        "article-byline": {
          "fontName": "AppleSDGothicNeo-Medium",
          "textColor": "#999999",
          "fontSize": 18
        }
      }
    }

    # Add the issue information
    apple_news_hash[:components] = [
      {
        role: "image",
        URL: self.cover_url(:home2x).to_s,
        caption: self.title,
        layout: "default-image"
      },
      {
        role: "title",
        text: self.title,
        layout: "default-title",
        textStyle: "default-title"
      },
      {
        role: "byline",
        text: "#{self.release.strftime('%B, %Y')}",
        layout: "default-byline",
        textStyle: "default-byline"
      },
      {
        role: "body",
        text: editors_letter,
        layout: "default-body",
        textStyle: "default-body"
      },
      {
        role: "divider",
        layout: "default-divider",
        "stroke": {
          color: "#DBDBDB",
          width: 2
        }
      }
    ]

    # Add the article information
    self.ordered_articles.each do |article|
      apple_news_hash[:components].push(
        {
          role: "section",
          components: [
            {
              role: "photo",
              URL: article.first_image.try(:data).to_s.blank? ? ActionController::Base.helpers.image_path("fallback/no_image.jpg") : article.first_image.data.to_s,
              caption: article.first_image.try(:caption).to_s.blank? ? "No caption" : ActionController::Base.helpers.strip_tags(article.first_image.try(:caption)),
              layout: "article-photo"
            },
            {
              role: "title",
              text: article.title,
              layout: "article-title",
              textStyle: "article-title"
            },
            { role: "byline",
              text: article.teaser.blank? ? article.categories.first.display_name.to_s : ActionController::Base.helpers.strip_tags(article.teaser),
              layout: "article-byline",
              textStyle: "article-byline"
            },
            {
              role: "divider",
              layout: "default-divider",
              "stroke": {
                color: "#DBDBDB",
                width: 2
              }
            }
          ]
        }
      )
    end
    return apple_news_hash.to_json
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
    # Note: Not sure this actually works, might have to export the test magazine in-app purchase and copy/paste the country/price matrix. Dammit.
    'AU' + '; ' + (price * 10000).to_s
  end

  # CSV exporting for Google Play in-app purchases
  # "product_id","publish_state","purchase_type","autotranslate ","locale; title; description","autofill","country; price"
  comma do

    # These bits for NZ office

    number
    title
    keynote :teaser => 'Keynote'
    release { |release| release.strftime("%B %Y")}

    # These bits for google_play_store - no longer actually used.

    google_play_inapp_id 'product_id'
    google_play_published 'publish_state'
    google_play_purchase_type 'purchase_type'
    google_play_autotranslate 'autotranslate'
    google_play_locale_title_description 'locale; title; description'
    google_play_autofill 'autofill'
    google_play_country_price 'country; price'

  end

  def push_notification_text
    if not digital_exclusive
      return " The #{release.strftime("%B")} edition of New Internationalist magazine is ready to read."
    else
      return ""
    end
  end

  def self.setup_push_notifications(params)
    # sleep 3
    this_issue = Issue.find(params["issue_id"])
    input_params = params["/issues/#{this_issue.id}/setup_push_notification"]
    alert_text = input_params["alert_text"]
    device_id = input_params["device_id"]

    # Scheduled datetime is in UTC(GMT)
    scheduled_datetime = DateTime.new(input_params["scheduled_datetime(1i)"].to_i, input_params["scheduled_datetime(2i)"].to_i, input_params["scheduled_datetime(3i)"].to_i, input_params["scheduled_datetime(4i)"].to_i, input_params["scheduled_datetime(5i)"].to_i)

    if scheduled_datetime > DateTime.now
      # It will be set below
    else
      scheduled_datetime = nil
    end

    data = {
      body: "#{alert_text + this_issue.push_notification_text}",
      badge: "Increment",
      name: this_issue.number.to_s,
      publication: this_issue.release.to_time.iso8601.to_s,
      railsID: this_issue.id.to_s,
      title: "New Internationalist",
      deliver_after: scheduled_datetime
    }

    if device_id.empty?
      # Loop thorugh all Android PushRegistration tokens and setup one push with an array of tokens
      android_tokens = []
      PushRegistration.where(device: 'android').each do |p|
        android_tokens << p.token
      end

      # Setup notifications in batches of 1,000 tokens.
      if not android_tokens.empty? and android_tokens.count > 1000
        android_tokens.each_slice(1000).to_a.each do |tokens|
          # Setup push notifications for Android devices
          logger.info "Creating #{tokens.count} Android push notifications."
          android_response = ApplicationHelper.rpush_create_android_push_notification(tokens, data)
          logger.info "Android push notifications response: #{android_response}"
        end
      elsif not android_tokens.empty?
        # Setup push notifications for Android devices
        logger.info "Creating #{android_tokens.count} Android push notifications."
        android_response = ApplicationHelper.rpush_create_android_push_notification(android_tokens, data)
        logger.info "Android push notifications response: #{android_response}"
      else
        logger.warn "WARNING: No Android push notifications created."
      end

      # Loop through all iOS PushRegistration tokens and setup iOS messages
      ios_responses = []
      PushRegistration.where(device: 'ios').each do |p|
        ios_responses << ApplicationHelper.rpush_create_ios_push_notification(p.token, data)
      end
      if not ios_responses.empty?
        logger.info "Creating #{ios_responses} iOS push notifications."
        # Check that all iOS responses were OK
        ios_response = false
        ios_responses.each do |r|
          if r
            ios_response = true
          else
            logger.info "ERROR iOS push notification response: #{r}"
            ios_response = false
          end
        end
      else
        logger.warn "WARNING: No iOS push notifications created."
      end

    else
      # Test push!
      if input_params["test_device_android"] == "1"
        android_response = ApplicationHelper.rpush_create_android_push_notification([device_id], data)
        ios_response = true # Fake out a true response
      else
        android_response = true # Fake out a true response
        ios_response = ApplicationHelper.rpush_create_ios_push_notification(device_id, data)
      end
    end

    # The actual sending is in the admin panel
    # rpush_response = Rpush.push

    # Check if the push worked and finish
    if android_response and ios_response
      # Success!

      # Mark the scheduled to send date, unless a single device push was sent.
      if device_id.blank? and Rails.env.production?
        this_issue.notification_sent = scheduled_datetime
      end
      
      if this_issue.save
        # redirect_to admin_push_notifications_path, notice: "Push notifications setup!"
        logger.info "Push notifications setup!"
      else
        # redirect_to self, flash: { error: "Couldn't update issue after push successfully setup." }
        logger.error "PUSH NOTIFICATIONS ERROR: Couldn't update issue after push successfully setup."
      end
    else
      # FAIL! server error.
      # redirect_to self, flash: { error: "Failed to setup push notifications. Error: #{android_response} ... #{ios_response}" }
      logger.error "Failed to setup push notifications. Error: #{android_response} ... #{ios_response}"
    end
  end

  private

  def reprocess_image
    cover.recreate_versions!
    editors_photo.recreate_versions!
  end

end
