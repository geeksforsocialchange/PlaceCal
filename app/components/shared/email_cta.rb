# frozen_string_literal: true

# The "rather just email?" card under a contact form.
class Components::Shared::EmailCta < Components::Base
  register_output_helper :icon

  theme_scope :email_cta,
              parts: {
                root: 'The card.',
                content: 'The row inside the card: the text, then the email button.',
                heading: 'The card\'s heading.',
                body: 'The line under the heading.'
              },
              tokens: %i[--color-secondary --color-foreground-dark --color-foreground-darker --font-serif --font-weight-regular --font-weight-bold
                         --radius-card --text-card --text-2xl --text-detail]

  prop :heading, String
  prop :body, String
  prop :address, String

  def view_template
    UI::Card(variant: :highlight, padding: :lg, **part(:root)) do
      UI::Cluster(gap: :lg, justify: :between, **part(:content)) do
        div(class: 'text-foreground-darker') do
          # h2 (not h3) to keep the heading order correct after the page's h1.
          UI::Heading(size: :card, tone: :inherit, spacing: :xs, **part(:heading)) { @heading }
          p(**part(:body, class: 'text-detail text-foreground-darker')) { @body }
        end
        UI::Button(variant: :dark_invert, size: :lg, href: "mailto:#{@address}") do
          icon(:mail, size: '4')
          plain @address
        end
      end
    end
  end
end
