# frozen_string_literal: true

class Components::Sites::PullQuote < Components::Base
  theme_scope :pull_quote,
              parts: {
                root: 'The pull quote: the quote between its marks, then its source.',
                quote: 'The quoted words.'
              },
              tokens: %i[--color-primary --leading-normal --text-sm]

  prop :source, String
  prop :quote_context, String

  def view_template(&)
    div(**part(:root, class: 'flex flex-col gap-6 text-center my-4')) do
      blockquote(class: 'flex flex-col items-center justify-evenly gap-8 my-0 md:flex-row md:gap-5') do
        raw(view_context.icon(:home_quote_open, size: nil, css_class: 'size-10 shrink-0 text-primary'))
        p(**part(:quote, class: 'm-0 max-w-lg text-balance'), &)
        raw(view_context.icon(:home_quote_close, size: nil, css_class: 'size-10 shrink-0 text-primary'))
      end
      cite(class: 'contents not-italic text-primary') do
        strong { @source } if @source.present?
        span(class: 'text-sm leading-normal') { @quote_context } if @quote_context.present? && @source.present?
      end
    end
  end
end
