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
        Issue.all.each do |i|
          xml.entry do
            xml.id i.number
            xml.updated i.updated_at.to_datetime.rfc3339
            xml.published i.release.to_datetime.rfc3339
            xml.summary "#{i.title} - the #{i.release.strftime("%B %Y")} issue of New Internationalist magazine."
            xml['news'].cover_art_icons('size' => 'SOURCE', 'src' => i.cover_url(:png).to_s)
          end
        end
    end
    }

    Issue.all.each do |i|
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
  
end
