SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true, # mark all cookies as "Secure"
    httponly: true, # mark all cookies as "HttpOnly"
    samesite: {
      lax: true # mark all cookies as SameSite=lax
    }
  }
  config.hsts = "max-age=#{1.week.to_i}; includeSubdomains; preload"
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = "origin-when-cross-origin"
  config.csp = {
    # "meta" values. these will shaped the header, but the values are not included in the header.
    # report_only: true,      # default: false [DEPRECATED from 3.5.0: instead, configure csp_report_only]
    preserve_schemes: true, # default: false. Schemes are removed from host sources to save bytes and discourage mixed content.

    # directive values: these values will directly translate into source directives
    # default_src: %w(https: 'self'),
    default_src: %W(https: 'self'),
    base_uri: %w('self'),
    child_src: %w('self' *.recaptcha.net *.facebook.com *.facebook.net *.twitter.com *.youtube.com *.googletagmanager.com public.tableau.com uploads.knightlab.com player.vimeo.com *.google.com), # if child-src isn't supported, the value for frame-src will be set.
    connect_src: %w('self' wss: *.google-analytics.com),
    font_src: %W('self' data: *.gstatic.com #{ENV['CLOUDFRONT_SERVER']}.cloudfront.net),
    # form_action: %w('self' github.com),
    form_action: %w('self' syndication.twitter.com *.paypal.com),
    frame_ancestors: %w('none'),
    img_src: %W('self' data: https: *.newint.com.au *.fbcdn.net *.facebook.net *.facebook.com *.twimg.com *.doubleclick.net *.google-analytics.com *.twitter.com *.apple.com.edgekey.net *.cdninstagram.com #{ENV['S3_BUCKET']}.s3.amazonaws.com #{ENV['CLOUDFRONT_SERVER']}.cloudfront.net public.tableau.com),
    # media_src: %w(utoob.com),
    object_src: %w('self' *.youtube.com *.vimeo.com),
    # plugin_types: %w(application/x-shockwave-flash),
    script_src: %W('self' 'unsafe-inline' 'unsafe-eval' *.recaptcha.net *.ampproject.org public.tableau.com *.google-analytics.com *.twitter.com *.twimg.com *.facebook.com *.facebook.net *.googletagmanager.com *.googleadservices.com *.newrelic.com bam.nr-data.net #{ENV['CLOUDFRONT_SERVER']}.cloudfront.net *.google.com *.gstatic.com),
    style_src: %W('self' 'unsafe-inline' *.googleapis.com *.twitter.com *.twimg.com #{ENV['CLOUDFRONT_SERVER']}.cloudfront.net),
    upgrade_insecure_requests: Rails.env.production?, # see https://www.w3.org/TR/upgrade-insecure-requests/
    report_uri: %W(#{ENV["REPORT_URI_CSP"]})
  }
end