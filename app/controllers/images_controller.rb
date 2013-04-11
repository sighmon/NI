class ImagesController < ApplicationController
  # Cancan authorisation
  load_and_authorize_resource

  # GET /images
  # GET /images.json
  def index
  	@issue = Issue.find(params[:issue_id])
  	@article = Article.find(params[:article_id])
    @images = @article.images.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @images }
    end
  end

  # GET /images/1
  # GET /images/1.json
  def show
  	@issue = Issue.find(params[:issue_id])
  	@article = Article.find(params[:article_id])
    @showimage = Image.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @image }
    end
  end

  # GET /images/new
  # GET /images/new.json
  def new
  	@issue = Issue.find(params[:issue_id])
  	@article = Article.find(params[:article_id])
    @showimage = @article.images.build
    #@image = Image.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @image }
    end
  end

  # GET /images/1/edit
  def edit
    @issue = Issue.find(params[:issue_id])
    @article = Article.find(params[:article_id])
    @showimage = Image.find(params[:id])
  end

  # POST /images
  # POST /images.json
  def create
  	@issue = Issue.find(params[:issue_id])
  	@article = Article.find(params[:article_id])

    # HACK to fix jquery file upload
    data = params[:image].try(:[],:data)
    if data.kind_of?(Array)
      params[:image][:data] = data.first
    end

    @newimage = @article.images.create(params[:image].merge({ :position => (@article.images.collect{|i|i.position}.max or 0)+1 }))

    respond_to do |format|
      if @newimage.save
        format.html { redirect_to issue_article_path(@issue,@article), notice: 'Image was successfully created.' }
        format.js
        #format.json { render json: @newimage, status: :created, location: @newimage }
      else
        # _form partial expects "showimage"
        @showimage = @newimage
        format.html { render action: "new" }
        format.js
      end
    end
  end

  # PUT /images/1
  # PUT /images/1.json
  def update
    @image = Image.find(params[:id])

    respond_to do |format|
      if @image.update_attributes(params[:image])
        format.html { redirect_to issue_article_image_url, notice: 'Image was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @image.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /images/1
  # DELETE /images/1.json
  def destroy
    @image = Image.find(params[:id])
    @image.destroy

    respond_to do |format|
      format.html { redirect_to issue_article_images_url }
      format.json { head :no_content }
    end
  end

  def sort
    params[:image].each_with_index do |id, index|
      Image.update_all({position: index+1}, {id: id})
    end
    render nothing: true
  end

end
