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
          elsif e["element_type"] == "attribution"
            "<div class='attribution'>"+process_children(e, debug)+"</div>"
          elsif e["element_type"] == "pull_quote"
            alignment = e.at_xpath("field[@type='alignment']").text
            "<blockquote class='pull-#{alignment}'>"+process_children(e, debug)+"</blockquote>"
          elsif e["element_type"] == "block_quote"
            "<blockquote class='block-quote'>"+process_children(e, debug)+"</blockquote>"
          elsif e["element_type"] == "box"
            "<div class='box'>"+process_children(e,debug)+"</div>"
          elsif e["element_type"] == "factbox_third_width"
            alignment = e.at_xpath("field[@type='factbox_float']").text.downcase
            "<div class='factbox pull-#{alignment}'>"+process_children(e,debug)+"</div>"
          elsif e["element_type"] == "list"
            "<ul>"+process_children(e,debug)+"</ul>"
          elsif e["element_type"] == "at_a_glance"
            "<div class='at-a-glance'><h3>At a glance</h3><dl class='dl-horizontal'>"+process_children(e,debug)+"</dl></div>"
          elsif e["element_type"] == "star_ratings"
            "<div class='star-ratings'><h3>Star ratings</h3><dl class='dl-horizontal'>"+process_children(e,debug)+"</dl></div>"
          elsif e["element_type"] == "product_profile"
            "<div class='product-profile'>"+process_children(e,debug)+"</div>"
          elsif e["element_type"] == "author_note" or e["element_type"] == "author" or e["element_type"] == "postscript"
            "<div class='author-note'>"+process_children(e,debug)+"</div>"
          elsif e["element_type"] == "worldbeater"
            "<div class='worldbeater'><dl class='dl-horizontal'>"+process_children(e,debug)+"</dl></div>"
          elsif e["element_type"] == "making_waves"
            "<div class='making-waves'><dl class='dl-horizontal'>"+process_children(e,debug)+"</dl></div>"
          elsif e["element_type"] == "related_media" or e["element_type"] == "related_media_graphic"
            media_id = e["related_media_id"]
            image = Image.find_by_media_id(media_id)
            if image.try(:hidden)
              return nil
            end
            media_url = image.try(:data_url, :halfwidth)
            if not image.nil?
              "[File:#{image.try(:id)}]"
            else
              ""
            end
          elsif e["element_type"] == "footnotes"
            "<ol class='footnotes'>"+process_children(e,debug)+"</ol>"
          elsif ["page_no"].include? e["element_type"]
            #ignore
          elsif e["element_type"] == "word_power"
            "<div class='word-power'><div class='all-article-images article-image-cartoon no-shadow'><img alt='Word power by Mitchell and Richardson' title='Word power by Mitchell and Richardson' src='/assets/word-power@2x.jpg' width='300' /></div><dl class='dl-horizontal'>"+process_children(e,debug)+"</dl></div>"
          else
            "[UNKNOWN_CONTAINER{type="+e["element_type"]+"}: "+process_children(e,debug)+" /CONTAINER]" if debug
          end
        elsif e.name == "field"
          if ["paragraph","quote", "block_quote","an_author_note", "author", "postscript_text", "box_deck", "product_information", "factbox_content"].include? e["type"]
            # paragraph-like things
            "<p>#{e.text.gsub(/\n/, " ")}</p>"
          elsif ["attribution"].include? e["type"]
            # block quote attribution
            "<p class='attribution'>#{e.text.gsub(/\n/, " ")}</p>"
          elsif ["list_item"].include? e["type"]
            # list-like things
            "<li>#{e.text.gsub(/\n/, " ")}</li>"
          elsif e["type"].start_with?("aag_")
            # make a nice list of 'at a glance' items
            "<dt>#{e['type'].gsub(/aag_/, '').titlecase}</dt><dd>#{e.text.gsub(/\n/, " ")}</dd>"
          elsif ["attribution_link", "attribution_org"].include? e["type"]
            # attribution
            attribution_link = e.text.gsub(/\n/, "")
            if not attribution_link.include?("http://")
              attribution_link = "http://" + attribution_link
            end
            "<p><a href='#{attribution_link}'>#{attribution_link.gsub(/http:\/\//, " ")}</a></p>"
          elsif e["type"] == "last_profiled"
            @last_profiled_link = e.text
            return
          elsif e["type"] == "last_profiled_link"
            "<dt>Last Profiled</dt><dd><a href='#{@last_profiled_link}'>#{e.text}</a></dd>"
          elsif ["income_distribution", "life_expectancy", "literacy", "position_of_women", "freedom", "sexual_minorities", "politics"].include? e["type"]
            "<dt>#{e['type'].gsub(/_/, ' ').titlecase}</dt><dd>#{e.text}</dd>"
          elsif ["stars", "product_stars"].include? e["type"]
            star = "<i class='icon-star'></i> "
            star_rating = if e.text == "One"
                "#{star}"
              elsif e.text == "Two"
                "#{star}#{star}"
              elsif e.text == "Three"
                "#{star}#{star}#{star}"
              elsif e.text == "Four"
                "#{star}#{star}#{star}#{star}"
              elsif e.text == "Five"
                "#{star}#{star}#{star}#{star}#{star}"
              end
            if e["type"] == "product_stars"
              "<p>NI review: #{star_rating}</p>"
            else
              "<dd>#{star_rating}</dd>"
            end
          elsif e["type"] == "year"
            "<dt class='star-ratings-previous-year'>#{e.text}</dt>"
          elsif e["type"] == "product_link"
            product_link = e.text.gsub(/\n/, "")
            if not product_link.include?("http://")
              product_link = "http://" + product_link
            end
            "<p><a href='#{product_link}'>#{product_link.gsub(/http:\/\//, " ")}</a></p>"
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
          elsif ["wb_name", "wp_job", "wb_reputation", "wb_humour", "wb_cunning", "wb_sources"].include? e["type"]
            "<dt>#{e['type'].gsub(/^w._/, '').titlecase}</dt><dd>#{e.text}</dd>"
          elsif ["interview_with", "talked_to"].include? e["type"]
            "<dt>#{e['type'].gsub(/^w._/, '').titlecase}</dt><dd>#{e.text}</dd>"
          elsif ["issue_number","teaser","deck","page_no","alignment","hold","rel_media_class", "factbox_float"].include? e["type"]
            #ignore 
          elsif ["wp_language"].include? e["type"]
            "<h4>The language of the #{e.text}</h4>"
          elsif ["wp_definition_term"].include? e["type"]
            "<dt>#{e.text}</dt>"
          elsif ["wp_definition_desc"].include? e["type"]
            "<dd>#{e.text}</dd>"
          else
            "[unknown field type "+e["type"]+"]" if debug
          end
        else
          "[unknown tag #{e.name}]" if debug
        end 
      end

      if not article.hide_author_name
        if doc.xpath('//container[@element_type="author_note"]').empty? and doc.xpath('//container[@element_type="author"]').empty? and doc.xpath('//container[@element_type="postscript"]').empty?
          next_order = doc.xpath('//story/elements/*').collect{|e| e["order"].to_i }.max + 1
          doc.at_xpath('//story/elements') << '<container order="'+next_order.to_s+'" element_type="author_note"><field type="an_author_note">'+article.author+'</field></container>'
        end
      end

      return process_children(doc.xpath("//story/elements"),debug)

    end

    return ""

  end

  def expand_image_tags(body, debug = false)
    # Finds [File:xx] and [File:xx|cartoon] in body and converts it to nice div/img code
    body = body.gsub(/\[File:(?<id>\d+)(?:\|(?<all_options>[^\]]*))?\]/i) do 
      id = $~[:id]
      # weird "or" doesnt work here but || does...
      options = $~[:all_options].try(:split,"|") || []
      begin
        image = Image.find(id)

        version = :threehundred
        css_class = "article-image"
        image_width = 300
        credit_div = ""
        caption_div = ""

        if options.include?("full")
          version = nil
          css_class = "all-article-images article-image-cartoon article-image-full"
          image_width = 945
        elsif options.include?("cartoon")
          version = :sixhundred
          css_class = "all-article-images article-image-cartoon"
          image_width = 600
        elsif options.include?("centre")
          version = :threehundred
          css_class = "all-article-images article-image-cartoon article-image-centre"
          image_width = 300
        end
        
        if options.include?("ns")
          css_class += " no-shadow"
        end

        if options.include?("left")
          css_class += " article-image-float-none"
        end

        if options.include?("small")
          version = :threehundred
          css_class += " article-image-small"
          image_width = 150
        end

        media_url = image.try(:data_url, version)
        if image.credit
          credit_div = "<div class='new-image-credit'>#{image.credit}</div>"
        end
        if image.caption
          caption_div = "<div class='new-image-caption'>#{image.caption}</div>"
        end
        if media_url
          tag_method = method(:retina_image_tag)
          image_options = {:alt => "#{strip_tags(image.caption)}", :title => "#{strip_tags(image.caption)}", :size => "#{image_width}x#{image_width * image.height / image.width}"}
          if options.include?("full")
            tag_method = method(:image_tag)
          end
          image_html = "<div class='#{css_class}' itemprop='image' itemscope itemtype='https://schema.org/ImageObject'>"+tag_method.call(media_url, image_options)+caption_div+credit_div+"<meta itemprop='url' content='#{image.data_url.to_s}'><meta itemprop='width' content='#{image.width}'><meta itemprop='height' content='#{image.height}'></div>"
          if debug[:debug] == "amp"
            # Change the img tag to amp-img
            image_html.gsub(/<img/, '<amp-img layout=responsive')
          else
            image_html
          end
        else
          ""
        end
      rescue ActiveRecord::RecordNotFound
        if debug
          "=== IMAGE #{id} NOT FOUND! ==="
        else
          ""
        end
      end
    end

    # Now check for [Cover:00] tags which display a magazine cover and link to it
    body.gsub(/\[Cover:(?<id>\d+)(?:\|(?<all_options>[^\]]*))?\]/i) do 
      id = $~[:id]
      options = $~[:all_options].try(:split,"|") || []
      begin
        issue = Issue.find(id)

        version = :thumb
        css_class = "article-image article-image-small"
        image_width = 200
        credit_div = ""
        caption_div = ""

        if options.include?("small")
          version = :tiny
          css_class = "article-image article-image-small"
          image_width = 75
        end
        
        if options.include?("ns")
          css_class += " no-shadow"
        end

        if options.include?("left")
          css_class += " article-image-float-none"
        end

        cover_url = issue.try(:cover_url, version)

        if cover_url
          tag_method = method(:retina_image_tag)
          image_options = {:alt => "NI #{issue.number} - #{issue.title} - #{issue.release.strftime("%B, %Y")}", :title => "NI #{issue.number} - #{issue.title} - #{issue.release.strftime("%B, %Y")}", :size => "#{image_width}x#{image_width * 1000 / 1414}"}
          if options.include?("full")
            tag_method = method(:image_tag)
          end
          "<div class='#{css_class}'>"+link_to(tag_method.call(cover_url, image_options), issue_path(issue))+caption_div+credit_div+"</div>"
        else
          ""
        end
      rescue ActiveRecord::RecordNotFound
        if debug
          "=== COVER #{id} NOT FOUND! ==="
        else
          ""
        end
      end
    end
  end

  def remove_image_tags(body)
    body.gsub(/\[File:(.*?)\]/, "")
  end

  def expand_video_tags(body, debug = false)
    # Lets look for Youtube tags
    body.gsub(/\[Youtube:(?<embed_code>[^\]]*)?\]/i) do 
      # id = $~[:id]
      id = $~[:embed_code]
      # logger.info("******#{id}")
      "<iframe width='560' height='315' src='//www.youtube-nocookie.com/embed/#{id}?rel=0' frameborder='0' allowfullscreen></iframe>"
      # "<video width='320' height='240' controls><source src='https://youtube.googleapis.com/v/#{id}' type='video/mp4'>Your browser does not support the video tag.</video>"
    end
  end

end
