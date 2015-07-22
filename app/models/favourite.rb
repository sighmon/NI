class Favourite < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :article
  validates_presence_of :user_id
  validates_presence_of :article_id

end
