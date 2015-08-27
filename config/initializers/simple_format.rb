require 'action_view'
module ActionView::Helpers::TextHelper
  alias_method :old_simple_format, :simple_format
  def simple_format(text, html_options = {}, options = {})
    old_simple_format(text, html_options, options.merge({sanitize: false}))
  end
end

