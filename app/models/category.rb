class Category < ActiveRecord::Base
  attr_accessible :name, :display_name, :colour
  validates_uniqueness_of :name

  has_many :article_categorisations
  has_many :articles, :through => :article_categorisations

  def self.create_from_element(article,element)
    assets = 'http://bricolage.sourceforge.net/assets.xsd'
    c = Category.find_or_create_by_name(:name => element.try(:text))
    article.categories << c unless article.categories.include?(c)
    return c
  end

  def latest_published_article
    self.articles.select(&:published).max_by(&:publication)
  end

  def display_name
    read_attribute(:display_name) or generate_display_name
  end

  def short_display_name
    # Beware, ugly hack. :-)
    display_name.split(">").last.strip
  end

  def generate_display_name
    # From /columns/letters-from/ To "Letters from"
    # From /themes/aid/development/ To "Aid > Development"
    # From /features/special/ To "Special features"
    # From /features/web-exclusive/ To "Web exclusives"
    # From /columns/media/music/ To "Media > Music"
    # From /blog/books/ To "Blog > Books"
    # "Not > implemented (#{name})"
    pretty_name = name.gsub(/\/(themes|sections)\/(.*)\//) {$2.gsub(/-/," ").titleize}
    if pretty_name.include?("/")
      pretty_name = pretty_name.split("/").select{|s|not s.blank?}.map{|s| s.titleize}.join(" > ")
    end
    pretty_name
  end

  def colour_as_hex
    return "#%06x" % colour
  end

end
