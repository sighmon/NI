class CategoriesController < ApplicationController

  # Cancan authorisation
  load_and_authorize_resource

  def index
    @categories = @categories.sort_by(&:display_name)
  end

  def show
    @articles = @category.articles.sort_by(&:publication).reverse
  end

  def edit
    if @category.colour
      @category.colour = "##{@category.colour.to_s(16)}"
    end
  end

  def update
    if params[:category][:colour]
      params[:category][:colour] = params[:category][:colour].match("[0-9a-f]+")[0].hex
    end
    logger.info params
    respond_to do |format|
      if @category.update_attributes(params[:category])
        format.html { redirect_to @category, notice: 'Category was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

end
