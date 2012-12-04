class Favourite < ActiveRecord::Base
  attr_accessible :article_id, :created_at, :issue_id, :user_id
  belongs_to :user
  belongs_to :article
end
