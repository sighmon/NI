class CategoriesController < ApplicationController

  # Cancan authorisation
  load_and_authorize_resource

  def index
  	@categories = @categories.sort_by(&:display_name)
  end

  def show
  	@articles = @category.articles.sort_by(&:publication).reverse
  end
end
