class Issue < ActiveRecord::Base
  attr_accessible :number, :release, :title, :trialissue
  has_many :articles
end
