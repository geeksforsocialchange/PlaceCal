# frozen_string_literal: true

class Views::Layouts::Application < Phlex::HTML
  include Phlex::Rails::Layout
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ContentFor
  include Phlex::Rails::Helpers::ImageURL
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::AssetPath
  include Phlex::Rails::Helpers::CurrentPage
  include Phlex::Rails::Helpers::Request
  include Components

  # I18n translate helper, theme-aware (PlaceCal::ThemeTranslation), so a theme
  # can override page metadata strings for its own sites (#3368 D19).
  include PlaceCal::ThemeTranslation

  def view_template
    doctype
    html(lang: 'en') do
      head do
        csrf_meta_tags
        stylesheet_link_tag 'application', media: 'all', 'data-turbo-track': 'reload'
        stylesheet_link_tag 'public_tailwind', media: 'all', 'data-turbo-track': 'reload'
        # Legacy informational homepage pages (Views::Homepage::*) opt into the
        # home.scss bundle. Scoped via content_for so the nationwide directory
        # pages (which share the nil-site layout) don't inherit its body styling.
        stylesheet_link_tag 'home', media: 'all', 'data-turbo-track': 'reload' if content_for?(:home_styles)
        stylesheet_link_tag site.stylesheet_link, media: 'all', 'data-turbo-track': 'reload' if site&.stylesheet_link
        stylesheet_link_tag 'print', media: 'print', 'data-turbo-track': 'reload'
        render_theme_head
        preload_font('rawline/rawline-500.woff2')
        preload_font('rawline/rawline-700.woff2')
        preload_font('rawline/rawline-800.woff2')
        preload_font('trocchi/Trocchi-Regular.woff2')
        render_meta
        shim_url = asset_path('es-module-shims.js')
        script { raw safe("if(!HTMLScriptElement.supports||!HTMLScriptElement.supports('importmap')){var s=document.createElement('script');s.src='#{shim_url}';s.async=true;document.head.appendChild(s)}") }
        javascript_importmap_tags
        script { raw safe(matomo_tracking_js) } if Rails.env.production?
        meta(name: 'turbo-refresh-method', content: 'morph')
      end

      # app/assets/stylesheets/base/layout.scss
      # app/assets/stylesheets/home/_layout.scss
      # app/assets/stylesheets/home/pages/_index.scss
      body do
        div(class: [
              'page',
              *(if site.nil?
                  ['max-w-home bg-background border-none mx-auto']
                else
                  [
                    'max-w-xl bg-background mx-auto',
                    # tailwind border-n is px, not multiples of --spacing
                    'xl:border xl:border-x-[calc(--spacing(8))]',
                    'dt:border-text'
                  ]
                end)
            ]) do
          Navigation(navigation: navigation, site: site)
          # FIXME: move main elem into component to save excess divs
          main do
            Flash()
            yield
          end
          if site.nil?
            Directory::Footer()
          elsif (footer_class = site.theme_definition&.footer_class)
            # Theme footer slot (#3368 D1): the theme owns the whole footer.
            render footer_class.new(site: site, navigation: navigation)
          else
            Footer(site)
          end
        end
      end
    end
  end

  private

  # Theme head hook (#3368 D1/D3): a theme may register a Phlex component
  # (`theme.head "Foo::Components::Head"`) rendered here, after the stylesheet
  # chain, for fonts, manifest links and the like. The component is constructed
  # with no arguments; one that needs the site can read it from view_context the
  # way this layout does, or the theme's views can push markup through
  # content_for(:theme_head), which also works alongside a head component.
  def render_theme_head
    head_class = site&.theme_definition&.head_class
    render head_class.new if head_class
    raw content_for(:theme_head) if content_for?(:theme_head)
  end

  def render_meta
    title_text = compute_title
    description_text = compute_description

    title { title_text }
    meta(property: 'og:title', content: title_text)
    meta(property: 'og:site_name', content: site&.name || 'PlaceCal')

    link(rel: 'icon', type: 'image/png', href: image_url('favicon.png'))
    link(rel: 'apple-touch-icon', href: image_url('apple-touch-icon.png'))
    link(rel: 'manifest', href: '/manifest.webmanifest') if site
    meta(name: 'viewport', content: 'width=device-width, initial-scale=1')

    meta(name: 'description', content: description_text)
    meta(property: 'og:description', content: description_text)

    # Admin and Devise pages get no og:image — shared admin URLs redirect to
    # the login page, and link previews of those are just clutter (#2077).
    if request.subdomain == 'admin' || devise_page?
      # no og:image
    elsif content_for?(:image)
      meta(property: 'og:image', content: image_url(content_for(:image)))
      meta(property: 'og:image:alt', content: content_for(:image_alt)) if content_for?(:image_alt)
    elsif site
      # Generated share card for site homepages and other site pages (#2077)
      meta(property: 'og:image', content: og_image_url)
      meta(property: 'og:image:alt', content: t('og_image.alt.site', name: site.name))
      meta(property: 'og:image:width', content: '1200')
      meta(property: 'og:image:height', content: '630')
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
    # Pages served on multiple site subdomains (partners, events) set
    # :canonical to their directory-apex permalink so Google consolidates the
    # duplicates onto placecal.org instead of splitting authority per subdomain.
    # og:url follows it — all URL-identity signals should name the same page.
    canonical_href = content_for?(:canonical) ? content_for(:canonical) : request.original_url
    meta(property: 'og:url', content: canonical_href)
    link(rel: 'canonical', href: canonical_href)
    # Views can tighten robots via content_for (e.g. past events set noindex
    # so thousands of stale event pages don't dilute the site in the index).
    robots_content = content_for?(:robots) ? content_for(:robots) : 'noarchive'
    meta(name: 'robots', content: robots_content)

    json_ld = site ? site.to_json_ld(base_url: request.base_url) : Site.directory_json_ld(request.base_url)
    script(type: 'application/ld+json') { raw safe(json_ld.to_json) }
    return unless content_for?(:json_ld)

    script(type: 'application/ld+json') { raw safe(content_for(:json_ld)) }
  end

  def compute_title
    return 'PlaceCal | The Community Calendar' if current_page?(root_url) && site.nil?
    return "#{content_for(:title)} | #{site.name}" if content_for?(:title) && site&.name
    return "#{content_for(:title)} | PlaceCal" if content_for?(:title)

    site&.name || 'PlaceCal | The Community Calendar'
  end

  def devise_page?
    controller = view_context.controller
    controller.respond_to?(:devise_controller?) && controller.devise_controller?
  end

  def compute_description
    if content_for?(:description)
      content_for(:description).to_s
    else
      t('meta.description', site: site&.name)
    end
  end

  def preload_font(path)
    link(rel: 'preload', href: asset_path(path), as: 'font', type: 'font/woff2', crossorigin: 'anonymous')
  end

  # Matomo (stats.gfsc.community, site 1), cookieless: no consent banner needed.
  # disableCookies must be pushed before trackPageView, or the cookie is
  # already set by the time it runs.
  def matomo_tracking_js
    <<~JS
      var _paq = window._paq = window._paq || [];
      _paq.push(['disableCookies']);
      _paq.push(['trackPageView']);
      _paq.push(['enableLinkTracking']);
      (function() {
        var u = "https://stats.gfsc.community/";
        _paq.push(['setTrackerUrl', u + 'matomo.php']);
        _paq.push(['setSiteId', '1']);
        var d = document, g = d.createElement('script'), s = d.getElementsByTagName('script')[0];
        g.async = true; g.src = u + 'matomo.js'; s.parentNode.insertBefore(g, s);
      })();
    JS
  end

  def site
    view_context.instance_variable_get(:@site)
  end

  def navigation
    view_context.instance_variable_get(:@navigation)
  end
end
