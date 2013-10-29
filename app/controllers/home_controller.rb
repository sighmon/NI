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
end
