class HomeController < ApplicationController
  
  def index
  	if current_user.try(:admin?)
  		@issues = Issue.all
  	else
  		@issues = Issue.find_all_by_published(:true)
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
                    }
                  }
  end

  def newsstand

    @issues = []
    @feed = {}

    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
      xml.feed('xmlns' => 'http://www.w3.org/2005/Atom', 'xmlns:news' => 'http://itunes.apple.com/2011/Newsstand') do
        xml.updated DateTime.now.rfc3339
        Issue.all.sort_by(&:number).reverse.each do |i|
          xml.entry do
            xml.id i.number
            xml.updated i.updated_at.to_datetime.rfc3339
            xml.published i.release.to_datetime.rfc3339
            xml.summary "#{i.title} - the #{i.release.strftime("%B %Y")} issue of New Internationalist magazine."
            xml['news'].cover_art_icons do
              xml['news'].cover_art_icon('size' => 'SOURCE', 'src' => i.cover_url(:png).to_s)
            end
          end
        end
    end
    }

    Issue.all.sort_by(&:number).reverse.each do |i|
      issue = {}
      issue = "#{i.number}singleissue"
      @issues << issue
    end

    @feed = { "subscriptions" => [
      "12month",
      "12monthauto",
      "3monthauto"],
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
              xml.family('name' => '3 month auto-renewing subscription') do
                xml.locales do
                  xml.locale('name' => 'en-AU') do
                    xml.title '3 month auto-renewing subscription'
                    xml.description 'A 3 month auto-renewing subscription to New Internationalist magazine.'
                    xml.publication_name 'New Internationalist magazine'
                  end
                end
                xml.in_app_purchase do
                  xml.read_only_info do
                    xml.read_only_value('Waiting for Screenshot', 'key' => 'iap-status')
                  end
                  xml.product_id '3monthauto'
                  xml.type 'auto-renewable'
                  xml.duration '3 months'
                  xml.bonus_duration '1 month'
                  xml.products do
                    xml.product do
                      xml.cleared_for_sale 'true'
                      xml.intervals do
                        xml.interval do
                          xml.start_date "#{DateTime.now.strftime('%Y-%m-%d')}"
                          xml.wholesale_price_tier '17'
                        end
                      end
                    end
                  end
                end
              end
              xml.family('name' => '1 year auto-renewing subscription') do
                xml.locales do
                  xml.locale('name' => 'en-AU') do
                    xml.title '1 year auto-renewing subscription'
                    xml.description 'A one year auto-renewing subscription to New Internationalist magazine.'
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
                  xml.bonus_duration '3 months'
                  xml.products do
                    xml.product do
                      xml.cleared_for_sale 'true'
                      xml.intervals do
                        xml.interval do
                          xml.start_date "#{DateTime.now.strftime('%Y-%m-%d')}"
                          xml.wholesale_price_tier '48'
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
                        xml.start_date "#{DateTime.now.strftime('%Y-%m-%d')}"
                        xml.wholesale_price_tier '48'
                      end
                    end
                  end
                end
              end
              # End of subscriptions
              # Loop through single issues
              Issue.all.sort_by(&:number).reverse.each do |i|
                xml.in_app_purchase do
                  xml.locales do
                    xml.locale('name' => 'en-AU') do
                      xml.title "#{i.number} - #{i.title} - single issue purchase"
                      xml.description "Purchase a single issue of the New Internationalist magazine, #{i.number} - #{i.title}."
                    end
                  end
                  xml.read_only_info do
                    xml.read_only_value('Waiting for Screenshot', 'key' => 'iap-status')
                  end
                  xml.product_id "#{i.number}singleissue"
                  xml.reference_name "#{i.number} - #{i.title} - single issue purchase"
                  xml.type 'non-consumable'
                  xml.products do
                    xml.product do
                      xml.cleared_for_sale 'true'
                      xml.intervals do
                        xml.interval do
                          xml.start_date "#{DateTime.now.strftime('%Y-%m-%d')}"
                          xml.wholesale_price_tier '7'
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

end
