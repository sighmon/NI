# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.paths << "#{Rails.root}/app/assets/html"
Rails.application.config.assets.precompile += %w(404.html 500.html 503.html error.html maintenance.html)

# Precompile per-controller JavaScript manifests so layouts can include them selectively.
controller_js_assets = Dir.glob(Rails.root.join("app/assets/javascripts/**/*.{js,coffee,js.coffee}")).map do |file|
  relative = Pathname(file).relative_path_from(Rails.root.join("app/assets/javascripts")).to_s
  relative.sub(/\.js\.coffee\z/, ".js").sub(/\.coffee\z/, ".js")
end
Rails.application.config.assets.precompile += controller_js_assets.uniq
