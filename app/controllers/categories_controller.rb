class CategoriesController < ApplicationController

  # Cancan authorisation
  load_and_authorize_resource

  # Cache index as it takes a long time to compute
  caches_action :index

  def index
    @categories = @categories.sort_by(&:display_name)
    @issues = Issue.all

    # Set meta tags
    @page_title = "Article categories"
    @page_description = "A list of categories and themes covered by articles in New Internationalist magazine."

    set_meta_tags :title => @page_title,
                  :description => @page_description,
                  :keywords => "themes, categories, category, new, internationalist, magazine, digital, edition",
                  :canonical => categories_url,
                  :alternate => [
                    {:href => "android-app://#{ENV['GOOGLE_PLAY_APP_PACKAGE_NAME']}/newint/categories"}, 
                    {:href => "ios-app://#{ENV['ITUNES_APP_ID']}/newint/categories"},
                    {:href => apple_news_url(format: :xml), :type => 'application/rss+xml', :title => 'RSS'}
                  ],
                  :open_graph => {
                    :title => @page_title,
                    :description => @page_description,
                    #:type  => :magazine,
                    :url   => categories_url,
                    :image => @issues.sort_by{|i| i.release}.last.try(:cover_url, :thumb2x).to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@#{ENV["TWITTER_NAME"]}",
                    :creator => "@#{ENV["TWITTER_NAME"]}",
                    :title => @page_title,
                    :description => @page_description,
                    :image => {
                      :src => @issues.sort_by{|i| i.release}.last.try(:cover_url, :thumb2x).to_s
                    }
                  }
  end

  def show
    @articles = @category.articles.sort_by(&:publication).reverse

    # Set meta tags
    @page_title = "Articles about #{@category.short_display_name}"
    @page_description = "All New Internationalist articles about #{@category.short_display_name}, ordered by date."
    @category_image = @category.try(:latest_published_article).try(:first_image).try(:data).to_s

    set_meta_tags :title => @page_title,
                  :description => @page_description,
                  :keywords => "#{@category.short_display_name}, new, internationalist, magazine, digital, edition",
                  :canonical => category_url(@category),
                  :alternate => [
                    {:href => "android-app://#{ENV['GOOGLE_PLAY_APP_PACKAGE_NAME']}/newint/categories"}, 
                    {:href => "ios-app://#{ENV['ITUNES_APP_ID']}/newint/categories"},
                    {:href => apple_news_url(format: :xml), :type => 'application/rss+xml', :title => 'RSS'}
                  ],
                  :open_graph => {
                    :title => @page_title,
                    :description => @page_description,
                    #:type  => :magazine,
                    :url   => category_url(@category),
                    :image => @category_image,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@#{ENV["TWITTER_NAME"]}",
                    :creator => "@#{ENV["TWITTER_NAME"]}",
                    :title => @page_title,
                    :description => @page_description,
                    :image => {
                      :src => @category_image
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
                        :iphone => "newint://categories/#{@category.id}",
                        :ipad => "newint://categories/#{@category.id}"
                      }
                    }
                  }
  end

  def edit
    if @category.colour
      # @category.colour = "##{@category.colour.to_s(16)}"
      @category.colour = @category.colour_as_hex
    end
  end

  def create
    # Expire the cache
    expire_action :action => :index
  end

  def update
    # Expire the cache
    expire_action :action => :index

    if params[:category][:colour]
      params[:category][:colour] = params[:category][:colour].match("[0-9a-f]+")[0].hex
    end
    logger.info params
    respond_to do |format|
      if @category.update_attributes(category_params)
        format.html { redirect_to @category, notice: 'Category was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  def colours
    Category.all.sort_by(&:display_name).each_with_index{|c,i| 
      c.colour = Category.hsv_to_rgb(i/(Category.count+1).to_f,0.5,1).collect{|n| "%02x" % n}.join.hex
      c.save
    }
    redirect_to categories_path, notice: 'Colours were updated.' 
  end

  private

  def category_params
    params.require(:category).permit(:name, :display_name, :colour)
  end

end
