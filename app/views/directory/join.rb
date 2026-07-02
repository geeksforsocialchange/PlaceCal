# frozen_string_literal: true

class Views::Directory::Join < Views::Base
  prop :contact_request, ContactRequest, reader: :private

  def view_template
    content_for(:title) { t('directory.join.hero.title') }

    Directory::PageHero(
      title: t('directory.join.hero.title'),
      kicker: t('directory.join.hero.kicker'),
      subtitle: t('directory.join.hero.subtitle'),
      breadcrumb_label: t('directory.join.hero.breadcrumb')
    )

    div(class: 'container-editorial py-8') do
      ContactForm(contact_request: contact_request, url: get_in_touch_path)
    end
  end
end
