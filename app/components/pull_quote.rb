# frozen_string_literal: true

class Components::PullQuote < Components::Base
  prop :source, String
  prop :quote_context, String
  prop :options, Hash

  def after_initialize
    @color_mode = @options[:light_mode] ? 'light' : 'dark'
  end

  def view_template(&)
    div(class: 'pullquote') do
      blockquote(class: "blockquote--#{@color_mode}") do
        raw(view_context.icon(:home_quote_open, size: nil))
        p(class: 'alt-title-small', &)
        raw(view_context.icon(:home_quote_close, size: nil))
      end
      cite do
        strong(class: 'h3-small') { @source } if @source.present?
        span(class: 'small') { @quote_context } if @quote_context.present? && @source.present?
      end
    end
  end
end
