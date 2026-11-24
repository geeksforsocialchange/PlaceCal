# frozen_string_literal: true

# A pull quote with its credit. Takes translated strings.
class Components::Join::Quote < Components::Join::Base
  register_output_helper :icon

  # :on_primary darkens the mark and credit, which fall below AA on the green band.
  TONES = {
    default: { ink: 'text-foreground-dark', mark: 'text-secondary', credit: :muted },
    on_primary: { ink: 'text-foreground-darker', mark: nil, credit: :inherit }
  }.freeze

  prop :text, String
  prop :by, String
  prop :tone, _Union(*TONES.keys), default: :default

  def view_template
    tone = TONES[@tone]
    blockquote(class: "m-0 #{tone[:ink]}") do
      UI::Stack(gap: :md) do
        span(class: ['block', tone[:mark]].compact.join(' ')) { icon(:home_quote_open, size: '12') }
        p(class: 'font-serif text-xl leading-snug') { @text }
        UI::Kicker(as: :footer, tone: tone[:credit]) { @by }
      end
    end
  end
end
