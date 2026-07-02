# frozen_string_literal: true

class Views::Join::Features < Views::Join::Base
  def view_template
    content_for(:title) { t('join.features.title') }

    section(class: 'py-10') do
      div(class: 'container-public') do
        breadcrumb([t('join.nav.features')])
        h1(class: 'join-headline m-0 mb-2') { t('join.features.title') }
        p(class: 'text-base leading-relaxed max-w-(--width-prose) mt-0 mb-8') { t('join.features.lede') }
        div(class: 'grid md:grid-cols-2 lg:grid-cols-3 gap-4') do
          t('join.features.list').each do |feature|
            JoinSite::FeatureCard(title: feature[:title], body: feature[:body])
          end
        end
      end
    end
  end
end
