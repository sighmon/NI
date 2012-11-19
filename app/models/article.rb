class Article < ActiveRecord::Base
  belongs_to :issue
  attr_accessible :author, :body, :publication, :teaser, :title, :trialarticle, :keynote, :source

  include Tire::Model::Search
  include Tire::Model::Callbacks

  # Index name for Heroku Bonzai/elasticsearch
  index_name BONSAI_INDEX_NAME

  def self.create_from_element(issue,element)
    assets = 'http://bricolage.sourceforge.net/assets.xsd'
    return issue.articles.create(
      :title => element.at_xpath("./assets:name",'assets' => assets ).try(:text),
      :teaser => element.at_xpath('./assets:elements/assets:field[@type="teaser"]','assets' => assets).try(:text),
      :author => element.xpath('./assets:contributors/assets:contributor','assets'=>assets).collect{|n| ['fname','mname','lname'].collect{|t| n.at_xpath("./assets:#{t}",'assets'=>assets).try(:text) }.select{|n|!n.empty?}.join(" ")}.join(","),
      :publication => DateTime.parse(element.at_xpath('./assets:cover_date','assets'=>assets).try(:text) ),
      # :body => Hash.from_xml(element.to_xml).to_json
      :source => element.to_xml
    )
  end

  def source_to_body
    if not self.source.blank?
      if self.body.blank?
        # TODO: Do some work to add in cross-head, pull-quotes, images into the right order with paragraphs and parse any HTML.
        # 
        doc = Nokogiri::XML(self.source)
        paragraphs = doc.xpath("//story/elements/field[@type='paragraph']").select{|n| n}.join("<br /><br />").gsub(/\n/, " ")
        self.body = paragraphs

        # Hack code to just render all 'fields' elements.
        # result = Hash.from_xml(self.source)["story"]["elements"]["field"]
        # self.body = result.join(" ")
      end
    end
  end

  # Doesn't seem to list all of the articles when no params.
  # def self.search(params)
  #   tire.search(load: true) do
  #     query { string params[:query]} if params[:query].present?
  #   end
  # end

end
