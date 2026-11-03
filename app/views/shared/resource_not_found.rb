# frozen_string_literal: true

class Views::Shared::ResourceNotFound < Views::Base
  theme_scope :not_found,
              parts: {
                root: 'The page\'s column.',
                title: 'The page\'s h1.',
                body: 'The line under the title.',
                links: 'The links on to the site\'s home, events and partners.'
              }

  def view_template
    div(**part(:root, class: 'container-narrow py-16 text-center')) do
      UI::Stack(gap: :lg, align: :center) do
        UI::Stack(gap: :sm, align: :center) do
          h1(**part(:title, class: 'text-hero')) { t('shared.resource_not_found.title') }
          p(**part(:body, class: 'text-subhead')) { t('shared.resource_not_found.body') }
        end
        UI::Cluster(as: :ul, gap: :sm, justify: :center, **part(:links)) do
          li { UI::Button(variant: :primary, href: root_path) { t('shared.resource_not_found.home') } }
          li { UI::Button(variant: :outline, href: events_path) { t('shared.resource_not_found.events') } }
          li { UI::Button(variant: :outline, href: partners_path) { t('shared.resource_not_found.partners') } }
        end
      end
    end
  end
end
