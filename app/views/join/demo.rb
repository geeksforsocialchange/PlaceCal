# frozen_string_literal: true

# "Book a demo" — the same ContactForm as the directory's get-in-touch page,
# posting to the join-side route (forms can't post across subdomains).
class Views::Join::Demo < Views::Join::Base
  prop :contact_request, ::ContactRequest, reader: :private

  def view_template
    content_for(:title) { t('join.demo.title') }

    section(class: 'py-10') do
      div(class: 'container-editorial') do
        div(class: 'text-center mb-8') do
          h1(class: 'join-headline m-0 mb-2') { t('join.demo.title') }
          p(class: 'text-base text-tertiary leading-relaxed max-w-(--width-prose-md) mx-auto m-0') { t('join.demo.lede') }
        end
        Shared::ContactForm(contact_request: contact_request, url: join_demo_path)
      end
    end
  end
end
