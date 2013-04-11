class Category < ActiveRecord::Base
  attr_accessible :name
  validates_uniqueness_of :name

  has_many :article_categorisations
  has_many :articles, :through => :article_categorisations

  def self.create_from_element(article,element)
    assets = 'http://bricolage.sourceforge.net/assets.xsd'
    c = Category.find_or_create_by_name(:name => element.try(:text))
    article.categories << c unless article.categories.include?(c)
    return c
  end

end
