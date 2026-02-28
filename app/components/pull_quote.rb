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
        div(class: 'max_width') do
          p(class: 'alt-title-small', &)
        end
      end
      cite do
        strong(class: 'h3-small') { @source }
        span(class: 'small') { @quote_context }
      end
    end
  end
end
