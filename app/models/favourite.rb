class Favourite < ActiveRecord::Base
  attr_accessible :article_id, :created_at, :issue_id, :user_id
  belongs_to :user
  belongs_to :article
  validates_presence_of :user_id
  validates_presence_of :article_id

end
