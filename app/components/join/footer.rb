# frozen_string_literal: true

class Components::Join::Footer < Components::Join::Base
  include Phlex::Rails::Helpers::MailTo

  def view_template
    footer(class: 'bg-home-background border-t-[5px] border-rules mt-16 pt-10 pb-6') do
      render_grid
      render_impressum
    end
  end

  private

  def render_grid
    div(class: 'container-public grid grid-cols-1 md:grid-cols-[1.4fr_1fr_1fr_1fr] gap-8') do
      render_brand_column
      render_link_column(t('join.footer.audiences'), audience_links)
      render_link_column(t('join.footer.product'), [
                           [t('join.footer.features'), join_features_path],
                           [t('join.footer.pricing'), join_pricing_path],
                           [t('join.footer.book_demo'), join_demo_path],
                           [t('join.footer.directory'), apex_url]
                         ])
      render_link_column(t('join.footer.about'), [
                           [t('join.footer.our_story'), join_our_story_path],
                           [t('join.footer.gfsc'), 'https://gfsc.studio'],
                           [t('join.footer.email'), 'mailto:hello@placecal.org']
                         ])
    end
  end

  def audience_links
    AUDIENCE_KEYS.map do |key|
      [t("join.audiences.#{key}.title"), audience_path(key)]
    end
  end

  def render_brand_column
    div do
      image_tag('home/icons/logo-dark.svg', class: 'h-10 mb-4', alt: t('join.footer.placecal_logo_alt'), width: 127, height: 40)
      div(class: 'font-serif text-base text-tertiary leading-relaxed max-w-(--width-search)') do
        plain t('join.footer.tagline')
      end
    end
  end

  def render_link_column(title, links)
    div do
      h2(class: 'allcaps-label text-foreground mb-3') { title }
      ul(class: 'list-none space-y-1') do
        links.each do |label, href|
          li do
            link_to(label, href, class: 'font-serif text-detail text-foreground no-underline hover:underline hover:decoration-primary')
          end
        end
      end
    end
  end

  def render_impressum
    div(class: 'container-public mt-6 pt-5 border-t-2 border-rules text-xs text-tertiary font-serif [&_p]:my-1',
        data_nosnippet: true) do
      Shared::Impressum()
    end
  end
end
