# frozen_string_literal: true

class Views::Layouts::Application < Phlex::HTML
  include Phlex::Rails::Layout
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::ImageURL
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::CurrentPage
  include Phlex::Rails::Helpers::Request
  include Components

  def view_template
    doctype
    html(lang: 'en') do
      head do
        csrf_meta_tags
        stylesheet_link_tag 'application', media: 'all', 'data-turbo-track': 'reload'
        stylesheet_link_tag 'public_tailwind', media: 'all', 'data-turbo-track': 'reload'
        link(rel: 'stylesheet', href: '/vendor/maplibre-gl.css', media: 'all', 'data-turbo-track': 'reload')
        stylesheet_link_tag site.stylesheet_link, media: 'all', 'data-turbo-track': 'reload' if site&.stylesheet_link
        stylesheet_link_tag 'print', media: 'print', 'data-turbo-track': 'reload'
        render_meta
        script(defer: true, 'data-domain': 'placecal.org', src: 'https://plausible.io/js/plausible.js') if Rails.env.production?
        javascript_include_tag 'es-module-shims', async: true
        javascript_importmap_tags
        meta(name: 'turbo-refresh-method', content: 'morph')
      end

      body do
        div(class: 'background') do
          Navigation(navigation: navigation, site: site)
          main do
            Flash()
            yield
          end
          footer do
            if site&.default_site?
              HomeFooter()
            else
              Footer(site)
            end
          end
        end
      end
    end
  end

  private

  def render_meta
    title_text = compute_title
    description_text = compute_description

    title { title_text }
    meta(property: 'og:title', content: title_text)
    meta(property: 'og:site_name', content: site&.name || 'PlaceCal')

    link(rel: 'icon', type: 'image/png', href: image_url('favicon.png'))
    link(rel: 'apple-touch-icon', href: image_url('apple-touch-icon.png'))
    meta(name: 'viewport', content: 'width=device-width, initial-scale=1')

    meta(property: 'description', content: description_text)
    meta(property: 'og:description', content: description_text)

    if content_for?(:image)
      meta(property: 'og:image', content: image_url(content_for(:image)))
    else
      meta(property: 'og:image', content: image_url('og/wide.png'))
      meta(property: 'og:image:alt', content: 'PlaceCal logo')
      meta(property: 'og:image:width', content: '1920')
      meta(property: 'og:image:height', content: '1080')
    end

    meta(property: 'og:type', content: 'website')
    meta(name: 'twitter:card', content: 'summary_large_image')
    meta(name: 'twitter:site', content: '@PlaceCal')
    meta(name: 'twitter:creator', content: '@gfscstudio')
    meta(property: 'og:url', content: request.original_url)
    meta(name: 'robots', content: 'noarchive')

    render_site_json_ld
    return unless content_for?(:json_ld)

    script(type: 'application/ld+json') { raw safe(content_for(:json_ld)) }
  end

  def render_site_json_ld
    site_data = if site&.default_site?
                  {
                    '@context' => 'https://schema.org',
                    '@type' => 'WebSite',
                    'name' => 'PlaceCal',
                    'url' => request.base_url,
                    'publisher' => {
                      '@type' => 'Organization',
                      'name' => 'PlaceCal',
                      'url' => 'https://placecal.org',
                      'sameAs' => ['https://twitter.com/PlaceCal']
                    }
                  }
                elsif site
                  data = {
                    '@context' => 'https://schema.org',
                    '@type' => 'WebSite',
                    'name' => site.name,
                    'url' => site.url || request.base_url
                  }
                  if site.logo.present?
                    data['publisher'] = {
                      '@type' => 'Organization',
                      'name' => site.name,
                      'logo' => site.logo.url
                    }
                  end
                  data
                end

    return unless site_data

    script(type: 'application/ld+json') { raw safe(site_data.to_json) }
  end

  def compute_title
    return 'PlaceCal | The Community Calendar' if current_page?(root_url) && site&.slug == 'default-site'
    return "#{content_for(:title)} | #{site.name}" if content_for?(:title) && site&.name
    return content_for(:title).to_s if content_for?(:title)

    site&.name || 'PlaceCal | The Community Calendar'
  end

  def compute_description
    if content_for?(:description)
      content_for(:description).to_s
    else
      I18n.t('meta.description', site: site&.name)
    end
  end

  def site
    view_context.instance_variable_get(:@site)
  end

  def navigation
    view_context.instance_variable_get(:@navigation)
  end
end
