# frozen_string_literal: true

class Views::Shared::ResourceNotFound < Views::Base
  theme_scope :not_found,
              parts: {
                root: 'The page\'s column.',
                title: 'The page\'s h1. On the directory the hero band holds it instead.',
                body: 'The line under the title.',
                links: 'The links on to the site\'s home, events and partners.'
              }

  prop :directory, _Boolean, default: false

  def view_template
    Directory::PageHero(title: t('shared.resource_not_found.title')) if @directory
    div(**part(:root, class: 'container-narrow py-16 text-center')) do
      UI::Stack(gap: :lg, align: :center) do
        UI::Stack(gap: :sm, align: :center) do
          h1(**part(:title, class: 'text-hero')) { t('shared.resource_not_found.title') } unless @directory
          p(**part(:body, class: 'text-subhead')) { t('shared.resource_not_found.body') }
        end
        @directory ? render_links(:dark, :dark_outline) : render_links(:primary, :outline)
      end
    end
  end

  private

  def render_links(home, others)
    UI::Cluster(as: :ul, gap: :sm, justify: :center, **part(:links)) do
      li { UI::Button(variant: home, href: root_path) { t('shared.resource_not_found.home') } }
      li { UI::Button(variant: others, href: events_path) { t('shared.resource_not_found.events') } }
      li { UI::Button(variant: others, href: partners_path) { t('shared.resource_not_found.partners') } }
    end
  end
end
