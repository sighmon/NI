class Category < ActiveRecord::Base
  belongs_to :article
  attr_accessible :name, :article_id

  has_many :articles

end
