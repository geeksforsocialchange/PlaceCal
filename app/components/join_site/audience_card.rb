# frozen_string_literal: true

# Linked card for one audience ("Who it's for"), used on the join homepage,
# the audiences index, and the "you might also be interested in" strip.
class Components::JoinSite::AudienceCard < Components::JoinSite::Base
  # Square card image per audience key (keys mirror DemoRequest::AUDIENCES
  # and the join.audiences.* locale tree).
  IMAGES = {
    'community_groups' => 'home/audiences/communities_square.jpg',
    'metropolitan_areas' => 'home/audiences/metro_square.jpg',
    'housing_providers' => 'home/audiences/housing_square.jpg',
    'social_prescribers' => 'home/audiences/social_square.jpg',
    'vcses' => 'home/audiences/vcses_square.jpg',
    'culture_tourism' => 'home/audiences/culture_square.jpg'
  }.freeze

  prop :audience, String, reader: :private

  def view_template
    a(href: audience_path(audience),
      class: 'with-no-sass flex flex-col gap-2 bg-home-background border-2 border-rules rounded-card p-5 no-underline text-foreground transition-all hover:border-secondary-deep hover:-translate-y-0.5') do
      div(class: 'aspect-square rounded-sm overflow-hidden bg-home-background-3') do
        image_tag(IMAGES.fetch(audience), class: 'w-full h-full object-cover', alt: t("join.audiences.#{audience}.image_alt"))
      end
      h3(class: 'font-serif font-regular text-card') { t("join.audiences.#{audience}.title") }
      p(class: 'text-detail text-tertiary leading-relaxed') { t("join.audiences.#{audience}.lede") }
      div(class: 'mt-auto text-secondary-deep font-bold text-detail') do
        plain t('join.audiences.see_pitch')
        span { safe(' &rarr;') }
      end
    end
  end
end
