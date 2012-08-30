class HomeController < ApplicationController
  def index
  	@issues = Issue.all
  end
end
