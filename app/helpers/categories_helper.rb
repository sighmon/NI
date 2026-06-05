module CategoriesHelper
  def categories_index_structured_data(categories, description)
    {
      "@context" => "https://schema.org",
      "@type" => "CollectionPage",
      "name" => "Article categories",
      "description" => strip_tags(description.to_s),
      "url" => categories_url,
      "mainEntity" => {
        "@type" => "ItemList",
        "itemListElement" => categories.collect.with_index(1) do |category, position|
          {
            "@type" => "ListItem",
            "position" => position,
            "name" => strip_tags(category.display_name.to_s),
            "url" => category_url(category)
          }
        end
      }
    }
  end

  def category_structured_data(category, articles, description)
    {
      "@context" => "https://schema.org",
      "@type" => "CollectionPage",
      "name" => "#{category.short_display_name} articles",
      "description" => strip_tags(description.to_s),
      "url" => category_url(category),
      "about" => {
        "@type" => "Thing",
        "name" => strip_tags(category.short_display_name.to_s)
      },
      "mainEntity" => {
        "@type" => "ItemList",
        "itemListElement" => articles.collect.with_index(1) do |article, position|
          {
            "@type" => "ListItem",
            "position" => position,
            "item" => {
              "@type" => "Article",
              "headline" => strip_tags(article.title.to_s),
              "url" => issue_article_url(article.issue, article),
              "datePublished" => article.publication.to_time.iso8601
            }
          }
        end
      }
    }
  end
end
