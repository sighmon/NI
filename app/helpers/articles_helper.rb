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
          elsif e["element_type"] == "list"
            "<ul>"+process_children(e,debug)+"</ul>"
          elsif e["element_type"] == "at_a_glance"
            "<div class='at-a-glance'><h3>At a glance</h3><dl class='dl-horizontal'>"+process_children(e,debug)+"</dl></div>"
          elsif e["element_type"] == "star_ratings"
            "<div class='star-ratings'><h3>Star ratings</h3><dl class='dl-horizontal'>"+process_children(e,debug)+"</dl></div>"
          elsif e["element_type"] == "author_note" or e["element_type"] == "author" or e["element_type"] == "postscript"
            "<div class='author-note'>"+process_children(e,debug)+"</div>"
          elsif e["element_type"] == "related_media" or e["element_type"] == "related_media_graphic"
            media_id = e["related_media_id"]
            image = Image.find_by_media_id(media_id)
            if image.try(:hidden)
              return nil
            end
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
          if ["paragraph","quote","an_author_note", "author", "postscript_text", "box_deck"].include? e["type"]
            # paragraph-like things
            "<p>#{e.text.gsub(/\n/, " ")}</p>"
          elsif ["list_item"].include? e["type"]
            # list-like things
            "<li>#{e.text.gsub(/\n/, " ")}</li>"
          elsif e["type"].start_with?("aag_")
            # make a nice list of 'at a glance' items
            "<dt>#{e['type'].gsub(/aag_/, '').titlecase}</dt><dd>#{e.text.gsub(/\n/, " ")}</dd>"
          elsif e["type"] == "last_profiled"
            @last_profiled_link = e.text
            return
          elsif e["type"] == "last_profiled_link"
            "<dt>Last Profiled</dt><dd><a href='#{@last_profiled_link}'>#{e.text}</a></dd>"
          elsif ["income_distribution", "life_expectancy", "literacy", "position_of_women", "freedom", "sexual_minorities", "politics"].include? e["type"]
            "<dt>#{e['type'].gsub(/_/, ' ').titlecase}</dt><dd>#{e.text}</dd>"
          elsif e["type"] == "stars"
            @star = "<i class='icon-star'></i> "
            if e.text == "One"
              "<dd>#{@star}</i></dd>"
            elsif e.text == "Two"
              "<dd>#{@star}#{@star}</dd>"
            elsif e.text == "Three"
              "<dd>#{@star}#{@star}#{@star}</dd>"
            elsif e.text == "Four"
              "<dd>#{@star}#{@star}#{@star}#{@star}</dd>"
            elsif e.text == "Five"
              "<dd>#{@star}#{@star}#{@star}#{@star}#{@star}</dd>"
            end
          elsif e["type"] == "year"
            "<dt class='star-ratings-previous-year'>#{e.text}</dt>"
          elsif e["type"] == "html" or e["type"] == "text"
            e.text.gsub(/\n/, " ")
          elsif ["rel_media_caption", "alt_text"].include? e["type"]
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
