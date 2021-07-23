class HomeController < ApplicationController

  include ActionView::Helpers::NumberHelper

  def free
    latest_free_issue = Issue.select{|issue| issue.trialissue and not issue.digital_exclusive}.sort_by(&:release).reverse.first
    if latest_free_issue
      redirect_to issue_path(latest_free_issue)
    else
      redirect_to root_url
    end
  end
  
  def index
  	@issues = Issue.where(published: true)

    @query_array = []

    @latest_issue = Issue.latest

    @quick_reads = Article.quick_reads

    @popular = Article.popular.first(3)

    @latest_issue_categories = Rails.cache.fetch("home_latest_issue_categories", expires_in: 12.hours) do
      latest_issue_categories = []
      @latest_issue.try(:articles).try(:each) do |article|
        latest_issue_categories |= article.categories
      end
      latest_issue_categories.sort_by(&:short_display_name)
    end

    @latest_free_issue = Rails.cache.fetch("home_latest_free_issue", expires_in: 12.hours) do
      Issue.latest_free
    end

    @features_category = Category.find_by_name("/features/")

    # compact removes the nil elements which fool the "if @keynotes" test in the view
    @keynotes = Rails.cache.fetch("home_keynotes", expires_in: 12.hours) do
      @issues.order(:release).reverse_order.first(24).collect{|i| i.keynote}.compact
    end

    @keynotes = @keynotes.sample(6).sort_by(&:publication)

    @facts = Rails.cache.fetch("home_facts", expires_in: 12.hours) do
      Category.find_by_name("/sections/facts/").try(:first_articles, 10)
    end

    @facts = @facts.try(:sample)

    @country_profile = Rails.cache.fetch("home_country_profile", expires_in: 12.hours) do
      Category.find_by_name("/columns/country/").try(:first_articles, 10)
    end

    @country_profile = @country_profile.try(:sample)

    @cartoon = Rails.cache.fetch("home_cartoon", expires_in: 12.hours) do
      Category.find_by_name("/columns/cartoon/").try(:first_articles, 10)
    end

    @cartoon = @cartoon.try(:sample)

    @agendas = Rails.cache.fetch("home_agendas", expires_in: 12.hours) do
      # @issues.sort_by(&:release).reverse.first(24).each.collect{|i| i.agendas}.flatten!.try(:compact)
      Category.find_by_name("/sections/agenda/").try(:first_articles, 100)
    end

    @agendas = @agendas.try(:sample, 3)

    @film = Rails.cache.fetch("home_film", expires_in: 12.hours) do
      Category.find_by_name("/columns/media/film/").try(:first_articles, 10)
    end

    @film = @film.try(:sample)

    @book = Rails.cache.fetch("home_book", expires_in: 12.hours) do
      Category.find_by_name("/columns/media/books/").try(:first_articles, 10)
    end

    @book = @book.try(:sample)

    @music = Rails.cache.fetch("home_music", expires_in: 12.hours) do
      Category.find_by_name("/columns/media/music/").try(:first_articles, 10)
    end

    @music = @music.try(:sample)

    @letters_from = Rails.cache.fetch("home_letters_from", expires_in: 12.hours) do
      Category.find_by_name("/columns/letters-from/").try(:first_articles, 10)
    end

    @letters_from = @letters_from.try(:sample)

    @making_waves = Rails.cache.fetch("home_making_waves", expires_in: 12.hours) do
      Category.find_by_name("/columns/makingwaves/").try(:first_articles, 10)
    end

    @making_waves = @making_waves.try(:sample)

    @world_beaters = Rails.cache.fetch("home_world_beaters", expires_in: 12.hours) do
      Category.find_by_name("/columns/worldbeaters/").try(:first_articles, 10)
    end

    @world_beaters = @world_beaters.try(:sample)

  	# Set meta tags
    @page_title_home = "New Internationalist Magazine Digital Edition"
    @page_description = "The New Internationalist is an independent monthly not-for-profit magazine that reports on action for global justice. We believe in putting people before profit, in climate justice, tax justice, equality, social responsibility and human rights for all."

    set_meta_tags :description => @page_description,
                  :keywords => "new, internationalist, magazine, archive, digital, edition, australia",
                  :canonical => root_url,
                  :alternate => [
                    {:href => "android-app://#{ENV['GOOGLE_PLAY_APP_PACKAGE_NAME']}/newint"}, 
                    {:href => "ios-app://#{ENV['ITUNES_APP_ID']}/newint"},
                    {:href => rss_url(format: :xml), :type => 'application/rss+xml', :title => 'RSS'}
                  ],
                  :fb => {
                    :app_id => ENV["FACEBOOK_APP_ID"]
                  },
                  :open_graph => {
                    :title => @page_title_home,
                    :description => @page_description,
                    :url   => root_url,
                    :image => @latest_issue.try(:cover_url, :thumb2x).to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@#{ENV["TWITTER_NAME"]}",
                    :creator => "@#{ENV["TWITTER_NAME"]}",
                    :title => @page_title_home,
                    :description => @page_description,
                    :image => {
                      :src => @latest_issue.try(:cover_url, :thumb2x).to_s
                    },
                    :app => {
                      :name => {
                        :iphone => ENV["ITUNES_APP_NAME"],
                        :ipad => ENV["ITUNES_APP_NAME"]
                      },
                      :id => {
                        :iphone => ENV["ITUNES_APP_ID"],
                        :ipad => ENV["ITUNES_APP_ID"]
                      },
                      :url => {
                        :iphone => "newint://",
                        :ipad => "newint://"
                      }
                    }
                  }
    
  end

  def newsstand

    @issues = []
    @feed = {}

    @published_issues = Issue.where(published: true)

    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
      xml.feed('xmlns' => 'http://www.w3.org/2005/Atom', 'xmlns:news' => 'http://itunes.apple.com/2011/Newsstand') do
        xml.updated DateTime.now.rfc3339
        @published_issues.sort_by(&:number).reverse.each do |i|
          xml.entry do
            xml.id i.number
            xml.updated i.updated_at.to_datetime.rfc3339
            xml.published i.release.to_datetime.rfc3339
            xml.summary "#{i.title} - the #{i.release.strftime("%B %Y")} issue of New Internationalist magazine. #{ActionView::Base.full_sanitizer.sanitize(i.keynote.try(:teaser))}"
            xml['news'].cover_art_icons do
              xml['news'].cover_art_icon('size' => 'SOURCE', 'src' => i.cover_url(:png).to_s)
            end
          end
        end
    end
    }

    @published_issues.sort_by(&:number).reverse.each do |i|
      issue = {}
      issue = "#{i.number}single"
      @issues << issue
    end

    @feed = { "subscriptions" => [
      "12month",
      "12monthauto",
      "3monthautomatic"],
      "issues" => @issues
    }

    respond_to do |format|
      format.json { render json: @feed.to_json }
      format.xml { render xml: builder.to_xml }
    end

  end

  def inapp

    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
      xml.package('xmlns' => 'http://apple.com/itunes/importer', 'version' => 'software5.0') do
        xml.provider ENV['INAPP_PROVIDER']
        xml.team_id ENV['INAPP_TEAM_ID']
        xml.software do
          xml.vendor_id ENV['INAPP_VENDOR_ID']
          xml.software_metadata do
            xml.in_app_purchases do
              xml.family('name' => 'Auto-renewing subscriptions') do
                xml.locales do
                  xml.locale('name' => 'en-AU') do
                    xml.title 'Auto-renewing subscriptions'
                    xml.description 'Auto-renewing subscription to New Internationalist magazine. You can choose between 12 monthly or 3 monthly auto-renewal periods.'
                    xml.publication_name 'New Internationalist magazine'
                  end
                end
                xml.in_app_purchase do
                  xml.read_only_info do
                    xml.read_only_value('Waiting for Screenshot', 'key' => 'iap-status')
                  end
                  xml.product_id '12monthauto'
                  xml.type 'auto-renewable'
                  xml.duration '1 year'
                  xml.bonus_duration '1 month'
                  xml.products do
                    xml.product do
                      xml.cleared_for_sale 'true'
                      xml.intervals do
                        xml.interval do
                          xml.start_date "#{(DateTime.now - 1).strftime('%Y-%m-%d')}"
                          xml.wholesale_price_tier '30'
                        end
                      end
                    end
                  end
                end
                xml.in_app_purchase do
                  xml.read_only_info do
                    xml.read_only_value('Waiting for Screenshot', 'key' => 'iap-status')
                  end
                  xml.product_id '3monthautomatic'
                  xml.type 'auto-renewable'
                  xml.duration '3 months'
                  xml.bonus_duration '1 month'
                  xml.products do
                    xml.product do
                      xml.cleared_for_sale 'true'
                      xml.intervals do
                        xml.interval do
                          xml.start_date "#{(DateTime.now - 1).strftime('%Y-%m-%d')}"
                          xml.wholesale_price_tier '10'
                        end
                      end
                    end
                  end
                end
              end
              xml.in_app_purchase do
                xml.locales do
                  xml.locale('name' => 'en-AU') do
                    xml.title '1 year subscription'
                    xml.description 'A one year subscription to New Internationalist magazine.'
                  end
                end
                xml.read_only_info do
                  xml.read_only_value('Waiting for Screenshot', 'key' => 'iap-status')
                end
                xml.product_id '12month'
                xml.reference_name '1 year subscription'
                xml.type 'subscription'
                xml.products do
                  xml.product do
                    xml.cleared_for_sale 'true'
                    xml.intervals do
                      xml.interval do
                        xml.start_date "#{(DateTime.now - 1).strftime('%Y-%m-%d')}"
                        xml.wholesale_price_tier '37'
                      end
                    end
                  end
                end
              end
              # End of subscriptions
              # Loop through single issues
              Issue.where(published: true).sort_by(&:number).reverse.each do |i|
                xml.in_app_purchase do
                  xml.locales do
                    xml.locale('name' => 'en-AU') do
                      xml.title "#{i.number} - #{i.title} - single issue purchase"
                      xml.description "#{ActionView::Base.full_sanitizer.sanitize(i.keynote.try(:teaser))}"
                    end
                  end
                  xml.read_only_info do
                    xml.read_only_value('Waiting for Screenshot', 'key' => 'iap-status')
                  end
                  xml.product_id "#{i.number}single"
                  xml.reference_name "#{i.number} - #{i.title} - single issue purchase"
                  xml.type 'non-consumable'
                  xml.products do
                    xml.product do
                      xml.cleared_for_sale 'true'
                      xml.intervals do
                        xml.interval do
                          xml.start_date "#{(DateTime.now - 1).strftime('%Y-%m-%d')}"
                          xml.wholesale_price_tier '5'
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
    end
    }

    respond_to do |format|
      if current_user.try(:admin?)
        format.xml { render xml: builder.to_xml }
        # CSV information that's included is in the Issue model under comma
        format.csv { render :csv => Issue.all.sort_by(&:number).reverse, :filename => DateTime.now.strftime("google-play-%Y-%m-%d-%H:%M:%S"), :write_headers => false }
      else
        format.xml { redirect_to root_url }
        format.csv { redirect_to root_url }
      end
    end

  end

  def google_merchant_feed

    @published_issues = Issue.where(published: true).sort_by(&:number).reverse

    # Remove the last issue - (more issues coming soon)
    if @published_issues.last.title == "More issues coming soon"
      @published_issues.pop
    end

    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
      xml.rss('xmlns:g' => 'http://base.google.com/ns/1.0', 'version' => '2.0') do
        xml.channel do
          xml.title "New Internationalist magazine digital edition"
          xml.link root_url
          xml.description "Buy a digital copy of New Internationalist magazine for your web browser, iOS or Android device."
          @published_issues.each do |i|
            xml.item do
              xml.title { xml.cdata ActionView::Base.full_sanitizer.sanitize(i.title) }
              xml.link { xml.cdata issue_url(i) }
              xml.mobile_link { xml.cdata issue_url(i) }
              xml.description { xml.cdata ActionView::Base.full_sanitizer.sanitize(i.keynote.try(:teaser)) }
              xml['g'].id "digitalapp#{i.number}"
              xml['g'].condition "new"
              xml['g'].price "#{number_with_precision((Settings.issue_price / 100.0), :precision => 2)} AUD"
              xml['g'].availability "in stock"
              xml['g'].image_link { xml.cdata i.cover_url.to_s }
              xml['g'].google_product_category "Media &gt; Magazines &amp; Newspapers"
              xml['g'].product_type "Magazine &gt; Digital edition"
              # xml['g'].gtin i.number
              xml['g'].identifier_exists "FALSE"
              xml['g'].brand "New Internationalist"
              xml['g'].shipping do
                xml['g'].service "Digital"
                xml['g'].price "0.00 AUD"
              end
            end
          end
        end
      end
    }

    respond_to do |format|
      format.json { render json: @published_issues.to_json }
      format.xml { render xml: builder.to_xml }
    end

  end

  def apple_news

    @published_issues = Issue.where(published: true).sort_by(&:number).reverse

    # Remove the last issue - (more issues coming soon)
    if @published_issues.last.title == "More issues coming soon"
      @published_issues.pop
    end

    # OLD Apple News format.. new one is JSON
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
      xml.rss('version' => '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom') do
        xml.channel do
          xml.title "New Internationalist magazine"
          xml.language "en-au"
          xml.link root_url
          xml['atom'].link(href: apple_news_url(:format => 'xml'), rel: 'self', type: 'application/rss+xml')
          xml.description "The New Internationalist is an independent monthly not-for-profit magazine that reports on action for global justice. We believe in putting people before profit, in climate justice, tax justice, equality, social responsibility and human rights for all."
          @published_issues.each do |i|
            xml.item do
              xml.title ActionView::Base.full_sanitizer.sanitize(i.title)
              xml.link issue_url(i)
              xml.guid issue_url(i)
              xml.source( url: apple_news_url(:format => 'xml') ) do
                xml.text "New Internationalist magazine"
              end
              xml.description { xml.cdata (ActionController::Base.helpers.image_tag(i.cover_url(:home2x).to_s, alt: i.title, title: i.title, size: '283x400', style: 'float:right;') + ActionView::Base.full_sanitizer.sanitize(i.editors_letter)) }
              xml.pubDate i.release.to_datetime.rfc822
            end
          end
        end
      end
    }

    # New Apple News format for Sept 2016
    latest_issue = @published_issues.first
    @apple_news_json = latest_issue.apple_news_json

    respond_to do |format|
      format.json { render json: @apple_news_json }
      format.xml { render xml: builder.to_xml }
    end

  end

  def apple_app_site_association

    render json: {
      applinks: {
        apps: [],
        details: [
          {
            appID: "#{ENV["ITUNES_APP_ID"]}.#{ENV["ITUNES_BUNDLE_ID"]}",
            paths: ["/issues*", "/categories"]
          }
        ],
      }
    }

  end

  def latest_cover
    # To get the latest cover from URL https://digital.newint.com.au/latest_cover.jpg
    # To get the full size cover, add ?full=true
    if ActionController::Base.helpers.sanitize(params[:full]) == "true"
      redirect_to Issue.latest.try(:cover_url)
    else
      redirect_to Issue.latest.try(:cover_url, :thumb2x)
    end
  end

  def tweet_url
    twitter_params = {
      :url => params[:url],
      :text => params[:text],
      :via => "#{ENV["TWITTER_NAME"]}"
      #:related => "#{ENV["TWITTER_NAME"]}"
    }
    redirect_to "https://twitter.com/share?#{twitter_params.to_query}"
  end

  def wall_post_url
    facebook_params = {
      :app_id => ENV["FACEBOOK_APP_ID"],
      :link => params[:url],
      # :picture => latest_cover.to_s,
      :name => "New Internationalist Magazine",
      :caption => params[:text],
      :description => params[:text],
      :redirect_uri => params[:url]
    }
    redirect_to "https://www.facebook.com/dialog/feed?#{facebook_params.to_query}"
  end

  def email_url
    email_params = {
      :body => params[:url],
      :subject => "New Internationalist Magazine"
    }
    redirect_to "mailto:?#{email_params.to_query}"
  end

end
