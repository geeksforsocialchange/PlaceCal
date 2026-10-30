# frozen_string_literal: true

# The "rather just email?" card under a contact form.
class Components::Shared::EmailCta < Components::Base
  register_output_helper :icon

  prop :heading, String
  prop :body, String
  prop :address, String

  def view_template
    div(class: 'join-email-cta flex flex-wrap items-center justify-between gap-5 mt-5 bg-secondary rounded-card py-6.5 px-7.5') do
      div do
        # h2 (not h3) to keep the heading order correct after the page's h1.
        h2(class: 'join-email-cta__heading font-serif font-regular text-xl leading-tight text-foreground-darker mt-0 mb-0.75') { @heading }
        p(class: 'join-email-cta__body text-detail text-foreground-darker') { @body }
      end
      a(href: "mailto:#{@address}", class: 'join-email-link inline-flex items-center gap-2.25 whitespace-nowrap no-underline py-2.75 px-5.5 ' \
                                           'rounded-pill bg-foreground text-background font-bold text-base ring-2 ring-foreground ' \
                                           'transition-colors hover:bg-background hover:text-foreground focus-visible:outline-foreground') do
        icon(:mail, size: '4')
        plain @address
      end
    end
  end
end
