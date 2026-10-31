# frozen_string_literal: true

class Components::Shared::Navigation < Components::Base
  theme_scope :navigation,
              parts: {
                root: 'The site header: branding, menu toggle and menu. The variant says whether it is the directory\'s or a site\'s.',
                branding: 'The link home holding the logo.',
                toggle: 'The menu button below lg on the directory and md on a site.',
                toggle_label: 'The visible "Menu" beside the toggle\'s icon. On the directory, and on a site whose theme sets menu_label.',
                menu: 'The nav holding the menu\'s list of links.',
                cta: 'The menu item holding the theme\'s call-to-action button. Only when the theme sets nav_cta.'
              },
              variants: { root: %i[directory site] },
              tokens: %i[--color-background --color-foreground --color-home-background --color-primary --color-rules --color-secondary --color-tertiary
                         --font-weight-semibold --font-weight-bold --font-weight-extra-bold --text-base --text-xl --text-2xl --tracking-wide]

  # Each element's classes for the nationwide directory and for a site, appended to its shared base classes.
  CONTEXTS = {
    directory: {
      header: ['container-public py-6 bg-background border-b border-rules'],
      branding: ['w-32 h-10 md:w-42 md:h-12'],
      toggle: ['text-foreground', 'md:me-4', 'lg:hidden'],
      menu: [
        # Matches container-public's padding so the dropdown sits flush without overflowing.
        '-mx-3 md:-mx-5',
        'pt-4 gap-0.5  lg:row-start-1 lg:col-start-2 lg:col-span-1',
        'md:flex-row md:gap-8 md:pt-3 md:pb-4 md:mt-6',
        'md:max-lg:is-hidden:py-0 md:max-lg:is-hidden:mt-4.5 md:max-lg:bg-home-background',
        # invisible takes the collapsed menu's links out of the tab order.
        'max-lg:is-hidden:h-0 max-lg:is-hidden:invisible',
        'lg:justify-end lg:items-baseline lg:mx-0 lg:mt-1.5 lg:py-0'
      ],
      item: ['max-md:bg-home-background max-md:py-3'],
      link: [
        'text-foreground font-bold',
        'after:h-0.75 after:mt-0.5 after:transition-colors after:duration-300',
        'hover:after:bg-foreground'
      ],
      link_active: 'after:bg-foreground'
    },
    site: {
      header: ['mx-4 pt-4', 'lg:mx-12 lg:py-6'],
      branding: ['w-42 h-12'],
      toggle: ['text-background', 'md:me-4', 'md:hidden'],
      menu: [
        '-mx-6 gap-1 mt-4',
        'max-md:pb-1 max-md:bg-tertiary max-md:is-hidden:h-0 max-md:is-hidden:pb-0',
        'max-md:is-hidden:invisible',
        'md:-mx-6',
        'md:max-lg:px-2 md:max-lg:bg-foreground',
        'lg:row-start-1 lg:col-start-2 lg:col-span-1 lg:gap-8 lg:m-0'
      ],
      item: [
        'py-4 duration-300 transition-none',
        'max-md:bg-foreground max-md:transition-colors max-md:hover:bg-tertiary',
        'md:max-lg:justify-evenly md:max-lg:grow'
      ],
      link: [
        'text-background font-extra-bold tracking-wide uppercase',
        'max-md:text-xl',
        'md:after:h-1 md:hover:after:bg-primary',
        'lg:text-foreground'
      ],
      link_active: 'md:after:bg-primary'
    }
  }.transform_values { |looks| looks.transform_values(&:freeze).freeze }.freeze

  prop :navigation, Array # Array of tuples of [name, URL]
  prop :site, _Nilable(::Site), default: nil
  # Passed down from the layout so the component stays a pure renderer.
  prop :region_tags, Array, default: -> { [] }
  prop :selected_region, _Nilable(::Tag), default: nil
  # Optional override for the nil-site CTA pill (defaults to "Join us" →
  # get-in-touch). The join marketing site swaps in "Book a demo".
  prop :cta_label, _Nilable(String), default: nil
  prop :cta_path, _Nilable(String), default: nil
  # Off where the page supplies its own h1.
  prop :home_heading, _Boolean, default: true

  def view_template
    header(**part(:root, variant: @site.nil? ? :directory : :site,
                         class: ['grid grid-cols-main-auto items-center print:hidden', *look[:header]], data: { controller: 'mobile-menu' })) do
      render_branding
      render_toggle
      render_menu
    end
  end

  private

  def look
    CONTEXTS[@site.nil? ? :directory : :site]
  end

  def render_branding
    link_to(root_path, **part(:branding, class: [
                                'row-start-1 col-start-1',
                                # svg for the bundled inline logos, img for uploaded ones
                                'logo:object-contain logo:max-w-full logo:max-h-full',
                                *look[:branding]
                              ])) do
      render_logo
      render_site_name
    end
  end

  def render_logo
    logo_url = @site&.logo&.url.presence
    if @site.nil?
      raw(view_context.svg_image('home/icons/logo-dark.svg', alt_text: 'PlaceCal'))
    elsif logo_url
      # An <img>, not inline markup: an uploaded SVG then can't run script or restyle the page.
      image_tag(logo_url, alt: @site.name)
    else
      raw(view_context.svg_image('header.svg', alt_text: 'PlaceCal'))
    end
  end

  def render_site_name
    if @site.nil?
      if request.path == '/' && @home_heading
        h1(class: 'sr-only') { 'PlaceCal' }
      else
        h2(class: 'sr-only') { 'PlaceCal' }
      end
    else
      h2(class: 'sr-only') { @site&.name }
      # Blank in core, so most sites announce just their name; a theme may
      # give itself a strapline through theme_overrides.
      strapline = t('navigation.site.strapline')
      p(class: 'sr-only') { strapline } if strapline.present?
    end
  end

  def render_menu
    nav(**part(:menu, id: 'site-menu', class: menu_nav_classes, aria_label: t('navigation.primary'),
                      data: { mobile_menu_target: 'menu' })) do
      ul(class: 'contents') do
        @navigation.each do |link_text, link_path|
          li(class: menu_li_classes) { active_link_to(link_text, link_path, data: { turbolinks: false }, base_css_class: menu_link_classes, active_css_class: menu_active_classes) }
        end
        render_join_button if @site.nil?
        render_region_filter if show_region_filter?
        render_theme_cta if theme_cta
      end
    end
  end

  # Theme region control (#3368): a theme may opt in with `nav_region_filter
  # true`, and even then it only actually shows once the site has something
  # to filter by, same as the region filter rendered above a listing.
  def show_region_filter?
    Current.theme.nav_region_filter? && @region_tags.size >= 2
  end

  def render_region_filter
    li do
      Sites::RegionFilter(tags: @region_tags, selected: @selected_region, embedded: true)
    end
  end

  # Theme call-to-action (#3368 D1): a theme may register `nav_cta`, for
  # example a Donate link; core renders it as the last nav item.
  def theme_cta
    return @theme_cta if defined?(@theme_cta)

    @theme_cta = Current.theme.nav_cta
  end

  def render_theme_cta
    options = {}
    # A CTA off to another site (a donation platform, say) opens in a new tab;
    # one pointing at a page of this site must not.
    if external_url?(theme_cta[:url])
      options[:target] = '_blank'
      options[:rel] = 'noopener'
    end

    li(**part(:cta, class: 'text-center max-md:py-3')) do
      UI::Button(variant: :light, href: theme_cta[:url], **options) { t(theme_cta[:label_key]) }
    end
  end

  # @param url [String]
  # @return [Boolean] whether the URL names a host other than this request's
  def external_url?(url)
    host = Addressable::URI.parse(url.to_s).host
    host.present? && host != request.host
  rescue Addressable::URI::InvalidURIError
    false
  end

  # Stays on get-in-touch until the join site's copy is agreed.
  def render_join_button
    li(class: 'text-center max-md:py-3') do
      UI::Button(variant: :secondary_flat, href: @cta_path || get_in_touch_path) { @cta_label || t('navigation.directory.join') }
    end
  end

  def menu_li_classes
    ['text-center', *look[:item]]
  end

  def menu_link_classes
    ['text-base no-underline', 'after:block after:mx-auto after:w-10', *look[:link]].join(' ')
  end

  def menu_active_classes
    look[:link_active]
  end

  def menu_nav_classes
    [
      'row-start-2 col-start-1 col-span-2 flex flex-col justify-evenly is-hidden',
      'h-auto overflow-clip transition-[display,height,margin-top,padding-block] duration-300',
      'md:flex-row',
      *look[:menu]
    ]
  end

  # The directory always labels its menu toggle; a site does so only when its
  # theme opts in with `menu_label true` (#3368 D1).
  def show_menu_label?
    @site.nil? || Current.theme.menu_label?
  end

  def render_toggle
    button(**part(:toggle, type: 'button', class: ['row-start-1 col-start-2 flex gap-2 ms-auto me-1.5 items-center', *look[:toggle]],
                           aria_label: t('navigation.menu'),
                           aria_expanded: 'false', aria_controls: 'site-menu',
                           data: { mobile_menu_target: 'toggle', action: 'click->mobile-menu#toggle', turbo: 'false' })) do
      # The accessible name is always there; the visible label beside the icon
      # is what a theme opts into.
      span(**part(:toggle_label, class: 'text-base font-semibold')) { t('navigation.menu') } if show_menu_label?
      raw(view_context.icon(:misc_menu, size: nil, css_class: 'size-8 fill-secondary'))
    end
  end
end
