# frozen_string_literal: true

class Components::Join::Footer < Components::Join::Base
  def view_template
    Shared::FooterLayout(tagline: t('join.footer.tagline'), logo_alt: t('join.footer.placecal_logo_alt'), columns:)
  end

  private

  def columns
    [
      [t('join.footer.audiences'), AUDIENCE_KEYS.map { |key| [t("join.audiences.#{key}.title"), audience_path(key)] }],
      [t('join.footer.product'), [
        [t('join.footer.features'), join_features_path],
        [t('join.footer.pricing'), join_pricing_path],
        [t('join.footer.book_demo'), join_demo_path],
        [t('join.footer.directory'), apex_url]
      ]],
      [t('join.footer.about'), [
        [t('join.footer.our_story'), join_our_story_path],
        [t('join.footer.gfsc'), 'https://gfsc.studio'],
        [t('contact.email'), "mailto:#{t('contact.email')}"]
      ]]
    ]
  end
end
