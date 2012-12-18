class HomeController < ApplicationController
  def index
  	if current_user.try(:admin?)
  		@issues = Issue.all
  	else
  		@issues = Issue.find_all_by_published(:true)
  	end
  end
end
