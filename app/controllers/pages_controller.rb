class PagesController < ApplicationController

  # Cancan authorisation
  load_resource :find_by => :permalink # will use find_by_permalink!(params[:id])
  authorize_resource

  # override default configuration for no_tracking pages
  SecureHeaders::Configuration.override(:no_tracking) do |config|
    config.csp[:child_src] = %w('self')
    config.csp[:img_src] = %W('self' data: *.newint.com.au)
    config.csp[:script_src] = %W('self')
    config.csp[:style_src] = %W('self' 'unsafe-inline')
    config.csp[:object_src] = %w('self')
    config.csp[:connect_src] = %w('self')
    config.csp[:form_action] = %w('self')
    config.csp[:font_src] = %w('self')
    config.csp[:report_uri] = %w('self')
    config.referrer_policy = "no-referrer"
  end
  
  # GET /pages
  # GET /pages.json
  def index
    @pages = Page.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @pages }
    end
  end

  # GET /pages/1
  # GET /pages/1.json
  def show
    # @page = Page.find(params[:id])
    # Now finding by permalink
    @page = Page.find_by_permalink!(params[:id])
    @no_tracking = ApplicationHelper.no_tracking(request)
    if @no_tracking
      # logger.info "No tracking for page #{@page.title}"
      NewRelic::Agent.ignore_transaction
      use_secure_headers_override(:no_tracking)
    end
    @current_issue = Issue.all.sort_by(&:release).last
    @first_image = ""
    @issues = Issue.where(published: true).sort_by(&:release).reverse.first(4)

    if not @page.body.try(:empty?)
      require 'nokogiri'
      doc = Nokogiri::HTML( @page.body )
      img_srcs = doc.css('img').map{ |i| i['src'] }
      @first_image = img_srcs[0]
    end

    if not @first_image
      @first_image = ENV["DEFAULT_PAGE_META_IMAGE"]
    end

    set_meta_tags :title => @page.title,
                  :description => @page.teaser,
                  :keywords => "new, internationalist, magazine, digital, edition, #{@page.title}",
                  :fb => {
                    :app_id => ENV["FACEBOOK_APP_ID"]
                  },
                  :open_graph => {
                    :title => @page.title,
                    :description => @page.teaser,
                    #:type  => :magazine,
                    :url   => page_url(@page.permalink),
                    :image => @first_image,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@#{ENV["TWITTER_NAME"]}",
                    :creator => "@#{ENV["TWITTER_NAME"]}",
                    :title => @page.title,
                    :description => @page.teaser,
                    :image => {
                      :src => @first_image
                    }
                  }

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @page }
    end
  end

  # GET /pages/new
  # GET /pages/new.json
  def new
    @page = Page.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @page }
    end
  end

  # GET /pages/1/edit
  def edit
    @page = Page.find_by_permalink!(params[:id])
  end

  # POST /pages
  # POST /pages.json
  def create
    @page = Page.new(page_params)

    respond_to do |format|
      if @page.save
        format.html { redirect_to @page, notice: 'Page was successfully created.' }
        format.json { render json: @page, status: :created, location: @page }
      else
        format.html { render action: "new" }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /pages/1
  # PUT /pages/1.json
  def update
    @page = Page.find_by_permalink!(params[:id])

    respond_to do |format|
      if @page.update_attributes(page_params)
        format.html { redirect_to @page, notice: 'Page was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @page.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.json
  def destroy
    @page = Page.find_by_permalink!(params[:id])
    @page.destroy

    respond_to do |format|
      format.html { redirect_to pages_url }
      format.json { head :no_content }
    end
  end

  private

  def page_params
    params.require(:page).permit(:body, :permalink, :title, :teaser)
  end
  
end
