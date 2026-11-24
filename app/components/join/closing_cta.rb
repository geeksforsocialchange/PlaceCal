# frozen_string_literal: true

# The salmon "Let's talk" band that ends a join page.
class Components::Join::ClosingCta < Components::Join::Base
  prop :heading, String
  prop :body, String
  prop :kicker, _Nilable(String), default: nil

  def view_template
    content_for(:join_footer_flush, true)
    Join::Section(band: :salmon) do
      div(class: 'max-w-(--width-prose-md) mx-auto text-center') do
        UI::Stack(gap: :md, align: :center) do
          UI::Kicker { @kicker } if @kicker
          UI::Heading(size: :section, tone: :inherit, balance: true) { @heading }
          UI::Text { @body }
          UI::Button(variant: :ink, size: :lg, href: join_demo_path) { t('join.cta.button') }
        end
      end
    end
  end
end
