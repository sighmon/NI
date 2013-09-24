class IssuesController < ApplicationController

  # Cancan authorisation
  load_and_authorize_resource :except => [:index]

  newrelic_ignore :only => [:email, :email_non_subscribers]

  # Devise authorisation
  # before_filter :authenticate_user!, :except => [:show, :index]

  # GET /issues
  # GET /issues.json

  def import
    @issue = Issue.find(params[:issue_id])
    @issue.import_articles_from_bricolage
    redirect_to issue_path(@issue)
  end

  def import_images
    @issue = Issue.find(params[:issue_id])
    @issue.articles.each do |article|
      article.import_media_from_bricolage
    end
    redirect_to issue_path(@issue)
  end

  def import_categories
    @issue = Issue.find(params[:issue_id])
    @issue.articles.each do |article|
      article.import_categories_from_source
    end
    redirect_to issue_path(@issue)
  end

  def index
    # @issues = Issue.all
    # Pagination
    # @issues = Issue.order("release").reverse_order.page(params[:page]).per(2)
    # Search
    # @issues = Issue.search(params)
    # TOFIX: TODO: Search + pagination?
    # @issues = Issue.order("release").reverse_order.page(params[:page]).per(2).search(params)

    @issues = Issue.search(params, current_user.try(:admin?))

    # Set meta tags
    @page_title = "Magazine archive"
    @page_description = "An archive of all the New Internationalist magazines available as digital editions."

    set_meta_tags :title => @page_title,
                  :description => @page_description,
                  :keywords => "new, internationalist, magazine, archive, digital, edition",
                  :canonical => issues_url,
                  :open_graph => {
                    :title => @page_title,
                    :description => @page_description,
                    #:type  => :magazine,
                    :url   => issues_url,
                    :image => @issues.sort_by{|i| i.release}.last.try(:cover_url, :thumb2x).to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@ni_australia",
                    :creator => "@ni_australia",
                    :title => @page_title,
                    :description => @page_description,
                    :image => {
                      :src => @issues.sort_by{|i| i.release}.last.try(:cover_url, :thumb2x).to_s
                    }
                  }

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @issues, callback: params[:callback] }
      format.json { render callback: params[:callback], json: @issues.to_json(
        # Q: do we need :editors_letter here? it can be quite large.
        :only => [:title, :id, :number, :editors_name, :editors_photo, :editors_letter, :release, :cover],
      ) }
    end
  end

  def email
    @issue = Issue.find(params[:issue_id])
    # sections_of_articles_definitions
    
    # Set meta tags
    @page_title = @issue.title
    @page_description = "Read the #{@issue.release.strftime("%B, %Y")} digital edition of the New Internationalist magazine - #{@issue.title}"

    set_meta_tags :title => @page_title,
                  :description => @page_description,
                  :keywords => "new, internationalist, magazine, digital, edition, #{@issue.title}",
                  :open_graph => {
                    :title => @page_title,
                    :description => @page_description,
                    #:type  => :magazine,
                    :url   => issue_url(@issue),
                    :image => @issue.cover_url(:thumb2x).to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@ni_australia",
                    :creator => "@ni_australia",
                    :title => @page_title,
                    :description => @page_description,
                    :image => {
                      :src => @issue.cover_url(:thumb2x).to_s
                    }
                  }
    respond_to do |format|
      format.html { render :layout => 'email' }
      format.text { render :layout => false }
    end
  end

  def email_non_subscribers
    @issue = Issue.find(params[:issue_id])

    respond_to do |format|
      format.html { render :layout => 'email' }
      format.text { render :layout => false }
    end
  end

  # GET /issues/1
  # GET /issues/1.json
  def show
    # @issue = Issue.find(params[:id])
    # TOFIX: Sort articles by :position using jquery

    # Load section definitions
    #sections_of_articles_definitions
    #moved to the model
    
    # Set meta tags
    @page_title = @issue.title
    @page_description = "Read the #{@issue.release.strftime("%B, %Y")} digital edition of the New Internationalist magazine - #{@issue.title}"

    set_meta_tags :title => @page_title,
                  :description => @page_description,
                  :keywords => "new, internationalist, magazine, digital, edition, #{@issue.title}",
                  :canonical => issue_url(@issue),
                  :open_graph => {
                    :title => @page_title,
                    :description => @page_description,
                    #:type  => :magazine,
                    :url   => issue_url(@issue),
                    :image => @issue.cover_url.to_s,
                    :site_name => "New Internationalist Magazine Digital Edition"
                  },
                  :twitter => {
                    :card => "summary",
                    :site => "@ni_australia",
                    :creator => "@ni_australia",
                    :title => @page_title,
                    :description => @page_description,
                    :image => {
                      :src => @issue.cover_url.to_s
                    }
                  }

    respond_to do |format|
      format.html # show.html.erb
      
      format.json { render json: @issue.to_json(
        #not super dry, see format block in #show
        # this is everything you should see about an issue without purchasing/subscribing
        # hoping that the only pay-walled content is :body
        :only => [:title, :id, :number, :editors_name, :editors_photo, :release, :cover],
        :methods => [:editors_letter_html],
        :include => { 
          :articles => { 
            :only => [:title, :teaser, :keynote, :featured_image, :featured_image_caption, :id],
            :include => {
              :images => {},
              :categories => { :only => [:name, :colour, :id] }
            }
          },
        } 
      ) }
    end
  end

  # GET /issues/new
  # GET /issues/new.json
  def new
    # @issue = Issue.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @issue }
    end
  end

  # GET /issues/1/edit
  def edit
    # @issue = Issue.find(params[:id])
    # Use cancan to check for individual authorisation
    # authorize! :update, @issue

    set_meta_tags :title => "Edit this Issue"
  end

  # POST /issues
  # POST /issues.json
  def create
    # @issue = Issue.new(params[:issue])

    respond_to do |format|
      if @issue.save
        format.html { redirect_to @issue, notice: 'Issue was successfully created.' }
        format.json { render json: @issue, status: :created, location: @issue }
      else
        format.html { render action: "new" }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /issues/1
  # PUT /issues/1.json
  def update
    # @issue = Issue.find(params[:id])

    respond_to do |format|
      if @issue.update_attributes(params[:issue])
        format.html { redirect_to @issue, notice: 'Issue was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /issues/1
  # DELETE /issues/1.json
  def destroy
    # @issue = Issue.find(params[:id])
    # For some reason @issue.destroy doesn't work anymore postgres?
    @issue.destroy
    # @issue.delete

    respond_to do |format|
      format.html { redirect_to issues_url }
      format.json { head :no_content }
    end
  end

end
