# frozen_string_literal: true

class Views::Join::Audiences < Views::Join::Base
  def view_template
    content_for(:title) { t('join.audiences.index.title') }

    section(class: 'py-10') do
      div(class: 'container-public') do
        breadcrumb([t('join.breadcrumbs.audiences')])
        h1(class: 'join-headline m-0 mb-2') { t('join.audiences.index.title') }
        UI::Text(measure: :prose, spacing: :xl) { t('join.audiences.index.lede') }
        UI::Grid(cols: { md: 2, lg: 3 }) do
          Join::Base::AUDIENCE_KEYS.each { |key| Join::AudienceCard(audience: key, heading_level: 2) }
        end
      end
    end
  end
end
