module ArticlesHelper

  def source_to_body(article, options = {})
    debug = options[:debug] or false
    if not article.source.blank?
      doc = Nokogiri::XML(article.source)

      def process_children(e, debug = false)
        e.xpath("*").sort_by{|n| n["order"].to_i}.collect{|e| process_element(e,debug)}.join("")
      end

      def process_element(e, debug = false)
        if e.name == "container"
          if e["element_type"] == "cross_head"
            "<h3>"+process_children(e, debug)+"</h3>"
          elsif e["element_type"] == "cross_head_2"
            "<h4>"+process_children(e, debug)+"</h4>"
          elsif e["element_type"] == "html"
            process_children(e, debug)            
          elsif e["element_type"] == "pull_quote"
            alignment = e.at_xpath("field[@type='alignment']").text 
            "<blockquote class='pull-#{alignment}'>"+process_children(e, debug)+"</blockquote>"
          elsif e["element_type"] == "box"
            "<div class='box'>"+process_children(e,debug)+"</div>"
          elsif (e["element_type"] == "author_note") or (e["element_type"] == "author")
            "<div class='author-note'>"+process_children(e,debug)+"</div>"
          elsif e["element_type"] == "related_media"
            media_id = e["related_media_id"]
            image = Image.find_by_media_id(media_id)
            media_url = image.try(:data_url, :halfwidth)
            if media_url
	            media_caption = e.at_xpath('./field[@type = "rel_media_caption"]').try(:text)
	            alignment = e.at_xpath("field[@type='alignment']").text
	            "<div class='article-image' style='float: #{alignment}'>"+retina_image_tag(media_url, :alt => "#{media_caption}", :title => "#{media_caption}", :size => "#{image.width}x#{image.height}")+process_children(e,debug)+"</div>"
        	end
          elsif e["element_type"] == "footnotes"
            "<ol class='footnotes'>"+process_children(e,debug)+"</ol>"
          elsif ["page_no"].include? e["element_type"]
            #ignore
          else
            "[UNKNOWN_CONTAINER{type="+e["element_type"]+"}: "+process_children(e,debug)+" /CONTAINER]" if debug
          end
        elsif e.name == "field"
          if ["paragraph","quote","an_author_note", "author"].include? e["type"]
            # paragraph-like things
            "<p>#{e.text.gsub(/\n/, " ")}</p>"
          elsif e["type"] == "html"
            e.text.gsub(/\n/, " ")
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

      return process_children(doc.xpath("//story/elements"),debug).html_safe

    end
  end

end
