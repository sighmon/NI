module IssuesHelper
    def issues_index_structured_data(issues, description)
        {
            "@context" => "https://schema.org",
            "@type" => "CollectionPage",
            "name" => "Magazine archive",
            "description" => strip_tags(description.to_s),
            "url" => issues_url,
            "mainEntity" => {
                "@type" => "ItemList",
                "itemListElement" => issues.collect.with_index(1) do |issue, position|
                    {
                        "@type" => "ListItem",
                        "position" => position,
                        "item" => {
                            "@type" => "Product",
                            "name" => strip_tags(issue.title.to_s),
                            "url" => issue_url(issue),
                            "image" => issue.cover_url(:thumb).to_s,
                            "sku" => issue.number.to_s,
                            "releaseDate" => issue.release.to_time.iso8601
                        }
                    }
                end
            }
        }
    end

    def issue_structured_data(issue, description)
        data = {
            "@context" => "https://schema.org",
            "@type" => "Product",
            "name" => strip_tags(issue.title.to_s),
            "description" => strip_tags(description.to_s),
            "brand" => {
                "@type" => "Brand",
                "name" => "New Internationalist"
            },
            "image" => issue.cover_url(:home).to_s,
            "url" => issue_url(issue),
            "sku" => issue.number.to_s,
            "releaseDate" => issue.release.to_time.iso8601,
            "offers" => {
                "@type" => "Offer",
                "availability" => "https://schema.org/InStock",
                "priceCurrency" => "AUD",
                "price" => cents_to_dollars(Settings.issue_price),
                "url" => issue_url(issue)
            },
            "publisher" => {
                "@type" => "Organization",
                "name" => "New Internationalist",
                "url" => root_url,
                "logo" => {
                    "@type" => "ImageObject",
                    "url" => asset_url("favicon-196x196.png"),
                    "width" => 196,
                    "height" => 196
                }
            }
        }

        articles = issue.ordered_articles.compact
        if articles.any?
            data["hasPart"] = articles.collect do |article|
                {
                    "@type" => "Article",
                    "headline" => strip_tags(article.title.to_s),
                    "url" => issue_article_url(issue, article)
                }
            end
        end

        data
    end

	# Adds CSS class to unpublished issues in issues index.
	def unpublished(issue)
        if not issue.published
            " issue-unpublished"
        end
    end
end
