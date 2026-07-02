# frozen_string_literal: true

class Views::Join::Audiences < Views::Join::Base
  def view_template
    content_for(:title) { t('join.audiences.index.title') }

    section(class: 'py-10') do
      div(class: 'container-public') do
        breadcrumb([t('join.breadcrumbs.audiences')])
        h1(class: 'join-headline m-0 mb-2') { t('join.audiences.index.title') }
        p(class: 'text-base leading-relaxed max-w-(--width-prose) mt-0 mb-8') { t('join.audiences.index.lede') }
        div(class: 'grid md:grid-cols-2 lg:grid-cols-3 gap-4') do
          DemoRequest::AUDIENCES.each { |key| JoinSite::AudienceCard(audience: key) }
        end
      end
    end
  end
end
