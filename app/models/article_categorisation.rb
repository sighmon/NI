class ArticleCategorisation < ActiveRecord::Base
  attr_accessible :position, :article_id, :category_id
  belongs_to :article
  belongs_to :category
  validates_uniqueness_of :article_id, :scope => [:category_id]
end
