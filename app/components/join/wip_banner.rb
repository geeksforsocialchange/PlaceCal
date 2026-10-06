# frozen_string_literal: true

# Launch notice for the join site while its copy and pricing are unagreed.
class Components::Join::WipBanner < Components::Join::Base
  def view_template
    aside(class: 'bg-home-blue text-foreground-dark', aria_label: t('join.wip.aria_label')) do
      div(class: 'container-public py-4 flex items-center gap-x-6 gap-y-2 flex-wrap') do
        strong(class: 'font-serif font-regular text-card') { t('join.wip.heading') }
        p(class: 'm-0 text-detail leading-relaxed flex-1 min-w-64') { t('join.wip.body') }
        a(href: "mailto:#{t('contact.email')}",
          class: 'with-no-sass text-detail font-bold text-foreground-dark underline hover:no-underline') do
          t('join.wip.cta')
        end
      end
    end
  end
end
