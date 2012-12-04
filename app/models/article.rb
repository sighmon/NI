class Article < ActiveRecord::Base
  belongs_to :issue
  attr_accessible :author, :body, :publication, :teaser, :title, :trialarticle, :keynote, :source, :featured_image, :featured_image_caption
  mount_uploader :featured_image, FeaturedImageUploader

  # join-model for favourites
  has_many :favourites
  has_many :users, :through => :favourites

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

  def source_to_body(options = {})
    debug = options[:debug] or false
    if not self.source.blank?
      if self.body.blank?
        
        doc = Nokogiri::XML(self.source)

        def process_children(e, debug = false)
          e.xpath("*").sort_by{|n| n["order"].to_i}.collect{|e| process_element(e,debug)}.join("")
        end

	      def process_element(e, debug = false)
          if e.name == "container"
            if e["element_type"] == "cross_head"
              "<h3>"+process_children(e, debug)+"</h3>"
            elsif e["element_type"] == "cross_head_2"
              "<h4>"+process_children(e, debug)+"</h4>"
            elsif e["element_type"] == "pull_quote"
              alignment = e.at_xpath("field[@type='alignment']").text 
              "<blockquote class='pull-#{alignment}'>"+process_children(e, debug)+"</blockquote>"
            elsif e["element_type"] == "box"
              "<div class='box'>"+process_children(e,debug)+"</div>"
            elsif e["element_type"] == "author_note"
              "<div class='author-note'>"+process_children(e,debug)+"</div>"
            elsif e["element_type"] == "related_media"
              media_id = e["related_media_id"]
              alignment = e.at_xpath("field[@type='alignment']").text 
              "<div class='article-image' style='float: #{alignment}'><img src='#{media_id}'/>"+process_children(e,debug)+"</div>"
            elsif e["element_type"] == "footnotes"
              "<ol class='footnotes'>"+process_children(e,debug)+"</ol>"
            elsif ["page_no"].include? e["element_type"]
              #ignore
            else
              "[UNKNOWN_CONTAINER{type="+e["element_type"]+"}: "+process_children(e,debug)+" /CONTAINER]" if debug
            end
          elsif e.name == "field"
            if ["paragraph","quote","an_author_note"].include? e["type"]
              # paragraph-like things
              "<p>#{e.text.gsub(/\n/, " ")}</p>"
            elsif e["type"] == "rel_media_caption"
              "<div class='new-image-caption'>#{e.text.gsub(/\n/, " ")}</div>"
            elsif e["type"] == "rel_media_credit"
              "<div class='new-image-credit'>#{e.text}</div>"
            elsif e["type"] == "cross_head"
              e.text
            elsif e["type"] == "cross_head_2"
              e.text
            elsif e["type"] == "foot_ref"
              "<li>#{e.text.gsub(/\n/, " ")}</li>"
            elsif e["type"] == "box_title"
              "<h4>#{e.text}</h4>"
            elsif ["issue_number","teaser","deck","page_no","alignment","hold","rel_media_class"].include? e["type"]
              #ignore 
            else
              "[unknown field type "+e["type"]+"]" if debug
            end
          else
            "[unknown tag #{e.name}]" if debug
          end 
        end

        self.body = process_children(doc.xpath("//story/elements"),debug).html_safe

      end
    end
  end

end
