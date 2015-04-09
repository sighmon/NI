class HomeController < ApplicationController

  include ActionView::Helpers::NumberHelper

  def free
    latest_free_issue = Issue.find_all_by_trialissue(:true).sort_by(&:release).reverse.first
    if latest_free_issue
      redirect_to issue_path(latest_free_issue)
    else
      redirect_to root_url
    end
  end
  
  def index
  	@issues = Issue.find_all_by_published(:true)

    @latest_free_issue = @issues.select{|issue| issue.trialissue}.reverse.first

    @features_category = Category.find_by_name("/features/")

    @keynotes = @issues.sort_by(&:release).reverse.first(6).each.collect{|i| i.keynote}

    facts_category = Category.find_by_name("/sections/facts/")
    if facts_category
      @facts = facts_category.first_ten_articles.sample
    end

    country_profile_category = Category.find_by_name("/columns/country/")
    if country_profile_category
      @country_profile = country_profile_category.first_ten_articles.sample
    end

    cartoon_category = Category.find_by_name("/columns/cartoon/")
    if cartoon_category
      @cartoon = cartoon_category.first_ten_articles.sample
    end

  	# Set meta tags
    @page_title_home = "New Internationalist Magazine Digital Edition"
    @page_description = "Welcome to the digital edition of the New Internationalist magazine, available for all digital devices with a browser."

    set_meta_tags :description => @page_description,
                  :keywords => "new, internationalist, magazine, archive, digital, edition, australia",
                  :open_graph => {
                    :title => @page_title_home,
                    :description => @page_description,
                    :url   => root_url,
                    :image => @issues.sort_by{|i| i.release}.last.try(:cover_url, :thumb2x).to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@ni_australia",
                    :creator => "@ni_australia",
                    :title => @page_title_home,
                    :description => @page_description,
                    :image => {
                      :src => @issues.sort_by{|i| i.release}.last.try(:cover_url, :thumb2x).to_s
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

    @published_issues = Issue.find_all_by_published(:true)

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
              Issue.find_all_by_published(:true).sort_by(&:number).reverse.each do |i|
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
      else
        format.xml { redirect_to root_url }
      end
    end

  end

  def google_merchant_feed

    @published_issues = Issue.find_all_by_published(:true).sort_by(&:number).reverse

    # Remove the last issue - (more issues coming soon)
    if @published_issues.last.title == "More issues coming soon"
      @published_issues.pop
    end

    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
      xml.rss('xmlns:g' => 'http://base.google.com/ns/1.0', 'version' => '2.0') do
        xml.channel do
          xml.title "New Internationalist magazine digital edition"
          xml.link root_url
          xml.description "Buy a digital copy of New Internationalist magazine for your web browser or iOS device."
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

  def latest_cover
    # To get the latest cover from URL https://digital.newint.com.au/latest_cover.jpg
    # To get the full size cover, add ?full=true
    full_cover = params[:full]
    published_issues = Issue.find_all_by_published(:true)
    if full_cover
      redirect_to published_issues.sort_by(&:release).last.try(:cover_url).to_s
    else
      redirect_to published_issues.sort_by(&:release).last.try(:cover_url, :thumb2x).to_s
    end
  end

end
