# frozen_string_literal: true

class Components::Sites::PullQuote < Components::Base
  theme_scope :pull_quote,
              parts: {
                root: 'The pull quote: the quote between its marks, then its source when it has one.',
                mark: 'A quotation mark. The variant says which.',
                quote: 'The quoted words.'
              },
              variants: { mark: %i[open close] },
              tokens: %i[--color-primary --leading-normal --text-sm]

  prop :source, String
  prop :quote_context, String

  def view_template(&)
    div(**part(:root, class: 'flex flex-col gap-6 text-center my-4')) do
      blockquote(class: 'flex flex-col items-center justify-evenly gap-8 my-0 md:flex-row md:gap-5') do
        raw(view_context.icon(:home_quote_open, size: nil, css_class: 'size-10 shrink-0 text-primary', **part(:mark, variant: :open)))
        p(**part(:quote, class: 'm-0 max-w-lg text-balance'), &)
        raw(view_context.icon(:home_quote_close, size: nil, css_class: 'size-10 shrink-0 text-primary', **part(:mark, variant: :close)))
      end
      if @source.present?
        cite(class: 'contents not-italic text-primary') do
          strong { @source }
          span(class: 'text-sm leading-normal') { @quote_context } if @quote_context.present?
        end
      end
    end
  end
end
