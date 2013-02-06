require 'fileutils'

Rake::Task['assets:precompile'].enhance do
  Rake::Task['assets:precompile_static_html'].invoke
end

namespace :assets do
  desc 'Compile the static 404 and 500 html template with the asset paths.'
  task :precompile_static_html do
    invoke_or_reboot_rake_task 'assets:precompile_static_html:all'
  end

  namespace :precompile_static_html do
    def internal_precompile_static_html
      # Ensure that action view is loaded and the appropriate
      # sprockets hooks get executed
      _ = ActionView::Base

      config = Rails.application.config
      config.assets.compile = true
      config.assets.digest  = true

      env      = Rails.application.assets
      target   = Rails.public_path
      compiler = Sprockets::StaticCompiler.new(
        env,
        target,
        ['404.html', '500.html'],
        :manifest_path => config.assets.manifest,
        :digest => false,
        :manifest => false
      )

      compiler.compile
    end

    task :all do
      ruby_rake_task('assets:precompile_static_html:primary', false)
    end

    task :primary => ['assets:environment', 'tmp:cache:clear'] do
      internal_precompile_static_html
    end
  end
end