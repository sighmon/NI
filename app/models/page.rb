class Page < ActiveRecord::Base
  attr_accessible :body, :permalink, :title, :teaser
  validates_uniqueness_of :permalink

  def to_param
  	permalink
  end

end
