class Issue < ActiveRecord::Base
  attr_accessible :number, :release, :title, :trialissue, :cover
  has_many :articles
  has_many :purchases
  has_many :users, :through => :purchases
  mount_uploader :cover, CoverUploader
end
