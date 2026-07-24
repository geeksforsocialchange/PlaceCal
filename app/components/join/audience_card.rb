# frozen_string_literal: true

# Linked card for one audience ("Who it's for"), used on the join homepage,
# the audiences index, and the "you might also be interested in" strip.
class Components::Join::AudienceCard < Components::Join::Base
  prop :audience, String, reader: :private
  # 3 under a section h2 (homepage, audience pages); 2 when the card grid sits
  # directly under the page h1 (who-its-for index) — heading order must not skip.
  prop :heading_level, Integer, default: 3

  def view_template
    a(href: audience_path(audience),
      class: 'with-no-sass flex flex-col gap-2 bg-home-background border-2 border-rules rounded-card p-5 no-underline text-foreground transition-all hover:border-secondary-deep hover:-translate-y-0.5') do
      div(class: 'aspect-square rounded-sm overflow-hidden bg-home-background-3') do
        image_tag(AUDIENCES.fetch(audience), class: 'w-full h-full object-cover', alt: t("join.audiences.#{audience}.image_alt"))
      end
      send(:"h#{@heading_level}", class: 'font-serif font-regular text-card m-0 mt-1') { t("join.audiences.#{audience}.title") }
      p(class: 'text-detail text-tertiary leading-relaxed m-0') { t("join.audiences.#{audience}.lede") }
      div(class: 'mt-auto pt-1 text-secondary-strong font-bold text-detail') do
        plain t('join.audiences.see_pitch')
        span { safe(' &rarr;') }
      end
    end
  end
end
