# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://digital.newint.com.au"
# pick a place safe to write the files
SitemapGenerator::Sitemap.public_path = 'tmp/'
# store on S3 using Fog
SitemapGenerator::Sitemap.adapter = SitemapGenerator::WaveAdapter.new
# inform the map cross-linking where to find the other maps
SitemapGenerator::Sitemap.sitemaps_host = "https://#{CarrierWave::Uploader::Base.fog_directory}.s3.amazonaws.com/"
# pick a namespace within your bucket to organize your maps
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  add('/', :alternates => [{
    :href => "ios-app://#{ENV['ITUNES_APP_ID']}/newint"
  }, {
    :href => "android-app://au.com.newint.newinternationalist/newint"
  }])

  # Add '/issues'
  add issues_path, :priority => 0.7, :changefreq => 'daily', :alternates => [{
    :href => "ios-app://#{ENV['ITUNES_APP_ID']}/newint/issues"
  }, {
    :href => "android-app://au.com.newint.newinternationalist/newint/issues"
  }]

  # Add all issues:
  Issue.find_each do |issue|
    if issue.published?
      add issue_path(issue), :lastmod => issue.updated_at, :alternates => [{
        :href => "ios-app://#{ENV['ITUNES_APP_ID']}/newint/issues/#{issue.id}"
      }, {
        :href => "android-app://au.com.newint.newinternationalist/newint/issues/#{issue.id}"
      }]

      # Add articles if it's a trial issue or trial article
      issue.articles.each do |article|
        if issue.trialissue? or article.trialarticle?
          add issue_article_path(issue,article), :lastmod => article.updated_at, :alternates => [{
            :href => "ios-app://#{ENV['ITUNES_APP_ID']}/newint/issues/#{issue.id}/articles/#{article.id}"
          }, {
            :href => "android-app://au.com.newint.newinternationalist/newint/issues/#{issue.id}/articles/#{article.id}"
          }]
        end
      end

      # News sitemap wasn't accepted by Google. :-(
      # issue.articles.each do |article|
      #   categories_list = "newint"
      #   article.categories.each do |category|
      #     categories_list = categories_list + ", " + category.short_display_name
      #   end
      #   add(issue_article_path(issue,article), :news => {
      #       :publication_name => "New Internationalist",
      #       :publication_language => "en",
      #       :title => article.title,
      #       :keywords => categories_list,
      #       # :stock_tickers => "SAO:PETR3",
      #       :publication_date => article.created_at,
      #       :access => "Subscription"
      #       # :genres => "PressRelease"
      #   })
      # end
    end
  end

  # Add categories:
  Category.find_each do |category|
    add category_path(category), :priority => 0.4, :lastmod => category.updated_at, :alternates => [{
        :href => "ios-app://#{ENV['ITUNES_APP_ID']}/newint/issues/categories"
      }, {
        :href => "android-app://au.com.newint.newinternationalist/newint/categories"
      }]
  end

end
