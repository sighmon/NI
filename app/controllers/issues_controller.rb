class IssuesController < ApplicationController

  # require 'rubygems'
  require 'zip'

  # Need to include the helper so we can call source_to_body for the zip file
  include ArticlesHelper

  # Cancan authorisation
  load_and_authorize_resource :except => [:index]

  newrelic_ignore :only => [:email, :email_non_subscribers, :email_others]

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
    @json_issues = Issue.select {|i| i.published?}.sort_by { |i| i.release }.reverse

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
      format.json { render callback: params[:callback], json: issues_index_to_json(@json_issues) }
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

  def email_others
    @issue = Issue.find(params[:issue_id])

    respond_to do |format|
      format.html { render :layout => 'email' }
      format.text { render :layout => false }
    end
  end

  def zip
    @issue = Issue.find(params[:issue_id])

    # Zip file structure
    # issueID
    # {
    #   issue.json
    #   number_cover.jpg
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

    zip_file_path = "#{Rails.root}/tmp/#{@issue.id}.zip"
    issue_json_file_location = "#{Rails.root}/tmp/#{@issue.id}.json"

    # Create temporary file for issue_id.json
    # TODO: Create the right type of issue.json file.
    File.open(issue_json_file_location, "w"){ |f| f << issues_index_to_json(@issue)}
    
    # Make zip file
    Zip::File.open(zip_file_path, Zip::File::CREATE) do |zipfile|

      if Rails.env.production?
        cover_path_to_add = @issue.cover_url
        editors_photo_path_to_add = @issue.editors_photo_url
      else
        cover_path_to_add = @issue.cover.path
        editors_photo_path_to_add = @issue.editors_photo.path
      end

      zipfile.add("issue.json", issue_json_file_location)
      zipfile.add(File.basename(@issue.cover_url), cover_path_to_add)
      zipfile.add(File.basename(@issue.editors_photo_url), editors_photo_path_to_add)

      # Loop through articles
      @issue.articles.each do |a|        
        # Create temporary file for issue_id.json
        File.open(article_json_file_location(a.id), "w"){ |f| f << a.to_json(article_information_to_include_in_json_hash) }

        # Add the article body
        if a.body
          body_to_zip = a.body
        else
          body_to_zip = source_to_body(a, :debug => current_user.try(:admin?))
        end
        File.open(article_body_file_location(a.id), "w"){ |f| f << body_to_zip }

        # Add article.json to article_id directory
        zipfile.add("#{a.id}/article.json", article_json_file_location(a.id))

        # Add body.html
        zipfile.add("#{a.id}/body.html", article_body_file_location(a.id))

        # Add featured image
        if Rails.env.production?
          featured_image_to_add = a.featured_image_url
        else
          featured_image_to_add = a.featured_image.path
        end
        if a.featured_image.to_s != ""
          zipfile.add("#{a.id}/#{File.basename(a.featured_image.to_s)}", featured_image_to_add)
        end

        # Loop through the images
        a.images.each do |i|
          if Rails.env.production?
            image_to_add = i.data_url
          else
            image_to_add = i.data.path
          end
          zipfile.add("#{a.id}/#{File.basename(i.data.to_s)}", image_to_add)
        end
      end
    end

    # Send zip file
    # TODO: upload zip file to S3 and save the URL to it in the issue model (Create zip url migration).
    # Don't forget to set fog_public = false so that no-one else can download the zip.
    # http://stackoverflow.com/questions/6735019/granular-public-settings-on-uploaded-files-with-fog-and-carrierwave

    File.open(zip_file_path, 'r') do |f|
      # Uncomment to download the zip file for checking locally also
      # send_data f.read, :type => "application/zip", :filename => "#{@issue.id}.zip", :x_sendfile => true
      @issue.zip = f
      @issue.save
    end

    # Delete the zip & tmp files.
    File.delete(zip_file_path)
    File.delete(issue_json_file_location)
    @issue.articles.each do |a|
      File.delete(article_json_file_location(a.id))
      File.delete(article_body_file_location(a.id))
    end

    redirect_to @issue, notice: "Zip created."
  end

  def article_json_file_location(article_id)
    "#{Rails.root}/tmp/article#{article_id}.json"
  end

  def article_body_file_location(article_id)
    "#{Rails.root}/tmp/article#{article_id}.html"
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
      
      format.json { render json: issue_show_to_json(@issue) }
    end
  end

  def issue_show_to_json(issue)
    issue.to_json(
      #not super dry, see format block in #show
      # this is everything you should see about an issue without purchasing/subscribing
      # hoping that the only pay-walled content is :body
      # this isn't used by the app - we get it from the issues.json
      #:only => [:title, :id, :number, :editors_name, :editors_photo, :release, :cover],
      #:methods => [:editors_letter_html],
      :only => [],
      :include => { 
        :articles => article_information_to_include_in_json_hash,
      } 
    )
  end

  def article_information_to_include_in_json_hash
    { 
      :only => [:title, :teaser, :keynote, :featured_image, :featured_image_caption, :id],
      :include => {
        :images => {},
        :categories => { :only => [:name, :colour, :id] }
      }
    }
  end

  def issues_index_to_json(issues)
    issues.to_json(
      # Q: do we need :editors_letter here? it can be quite large.
      :only => [:title, :id, :number, :editors_name, :editors_photo, :release, :cover],
      :methods => [:editors_letter_html]
    )
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
