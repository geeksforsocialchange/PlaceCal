# frozen_string_literal: true

class Components::PullQuote < Components::Base
  prop :source, String
  prop :quote_context, String
  prop :options, Hash

  def after_initialize
    @color_mode = @options[:light_mode] ? 'light' : 'dark'
  end

  def view_template(&)
    div(class: 'flex flex-col gap-6 text-center my-4') do
      blockquote(class: "flex flex-col items-center gap-8 tp:flex-row tp:gap-5 justify-evenly !my-0 #{'text-[#fffbef]' if @color_mode == 'dark'} [&_svg]:text-base-primary [&_svg]:size-10 [&_svg]:shrink-0") do
        raw(view_context.icon(:home_quote_open, size: nil))
        p(class: 'alt-title-small m-0 max-w-[860px] text-balance', &)
        raw(view_context.icon(:home_quote_close, size: nil))
      end
      cite(class: 'text-base-primary contents not-italic') do
        strong(class: 'h3-small') { @source } if @source.present?
        span(class: 'small') { @quote_context } if @quote_context.present? && @source.present?
      end
    end
  end
end
