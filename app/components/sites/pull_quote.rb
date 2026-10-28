# frozen_string_literal: true

class Components::Sites::PullQuote < Components::Base
  prop :source, String
  prop :quote_context, String
  prop :options, Hash

  def after_initialize
    @color_mode = @options[:light_mode] ? 'light' : 'dark'
  end

  def view_template(&)
    div(class: 'pullquote flex flex-col gap-6 text-center my-4') do
      blockquote(class: "blockquote--#{@color_mode} flex flex-col items-center justify-evenly gap-8 my-0 md:flex-row md:gap-5") do
        raw(view_context.icon(:home_quote_open, size: nil, css_class: 'size-10 shrink-0 text-primary'))
        p(class: 'alt-title-small m-0 max-w-lg text-balance', &)
        raw(view_context.icon(:home_quote_close, size: nil, css_class: 'size-10 shrink-0 text-primary'))
      end
      cite(class: 'contents not-italic text-primary') do
        strong(class: 'h3-small') { @source } if @source.present?
        span(class: 'text-sm leading-normal') { @quote_context } if @quote_context.present? && @source.present?
      end
    end
  end
end
