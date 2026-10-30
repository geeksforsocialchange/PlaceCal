# frozen_string_literal: true

# The "rather just email?" card under a contact form.
class Components::Shared::EmailCta < Components::Base
  register_output_helper :icon

  prop :heading, String
  prop :body, String
  prop :address, String

  def view_template
    UI::Card(variant: :highlight, padding: :lg, class: 'join-email-cta') do
      UI::Cluster(gap: :lg, justify: :between) do
        div do
          # h2 (not h3) to keep the heading order correct after the page's h1.
          h2(class: 'join-email-cta__heading font-serif font-regular text-xl leading-tight text-foreground-darker mt-0 mb-0.75') { @heading }
          p(class: 'join-email-cta__body text-detail text-foreground-darker') { @body }
        end
        UI::Button(variant: :dark_invert, size: :lg, href: "mailto:#{@address}", class: 'join-email-link') do
          icon(:mail, size: '4')
          plain @address
        end
      end
    end
  end
end
