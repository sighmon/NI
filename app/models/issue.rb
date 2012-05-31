class Issue < ActiveRecord::Base
  attr_accessible :number, :release, :title, :trialissue
  has_many :articles
  has_many :purchases
  has_many :users, :through => :purchases
end
