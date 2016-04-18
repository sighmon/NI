class Category < ActiveRecord::Base

  validates_uniqueness_of :name

  has_many :article_categorisations
  has_many :articles, :through => :article_categorisations

  after_commit :flush_cache

  def self.create_from_element(article,element)
    assets = 'http://bricolage.sourceforge.net/assets.xsd'
    c = Category.where(:name => element.try(:text)).first_or_create
    article.categories << c unless article.categories.include?(c)
    return c
  end

  def latest_published_article
    Category.cached_category_articles(self.id).first
  end

  def first_articles(number)
    Category.cached_category_articles(self.id).first(number)
  end

  def self.cached_category_articles(id)
    Rails.cache.fetch([name, id]) { find(id).articles.where("published" == true).order(:publication).reverse_order }
  end

  def flush_cache
    Rails.cache.delete([self.class.name, id])
  end

  def display_name
    read_attribute(:display_name) or generate_display_name
  end

  def short_display_name
    # Beware, ugly hack. :-)
    display_name.split(">").last.try(:strip)
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
    if colour
      return "#%06x" % colour
    else
      return "#FFFFFF"
    end
  end

  def self.hsv_to_rgb(h, s, v)
    h_i = (h*6).to_i
    f = h*6 - h_i
    p = v * (1 - s)
    q = v * (1 - f*s)
    t = v * (1 - (1 - f) * s)
    r, g, b = v, t, p if h_i==0
    r, g, b = q, v, p if h_i==1
    r, g, b = p, v, t if h_i==2
    r, g, b = p, q, v if h_i==3
    r, g, b = t, p, v if h_i==4
    r, g, b = v, p, q if h_i==5
    [(r*255).to_i, (g*255).to_i, (b*255).to_i]
  end

end
