# frozen_string_literal: true

# Tailwind classes are generally [ base, default site, partner site]

class Components::Navigation < Components::Base
  prop :navigation, Array # Array of tuples of [name, URL]
  prop :site, _Nilable(::Site), default: nil

  def view_template
    # FIXME: arbitrary values
    header(class: [
             'header grid grid-cols-[1fr_auto] items-center',
             ('header__default mx-3 py-6 md:mx-6' if @site&.default_site?),
             ('header__partner mx-4 pt-4 lg:py-4 lg:mx-[3.3rem] lg:py-[1.7rem]' unless @site&.default_site?)
           ], data: { controller: 'mobile-menu' }) do
      render_branding
      render_toggle
      render_menu
    end
  end

  private

  def render_branding
    link_to(root_path, class: [
              'header__branding',
              ("header__branding--#{@site&.slug}" if @site&.slug),
              # svg/img classes are here because partner svgs are inlined with File.read
              'row-start-1 col-start-1 [&>svg,&>img]:object-contain [&>svg,&>img]:max-w-full [&>svg,&>img]:max-h-full',
              # FIXME: arbitrary values
              ('w-[148px] h-[44px] md:w-[191px] md:h-[56px]' if @site&.default_site?),
              ('w-[187px] h-[55px]' unless @site&.default_site?)
            ]) do
      render_logo
      render_site_name
    end
  end

  def render_logo
    logo_url = @site&.logo&.url.presence
    if @site&.default_site?
      raw(view_context.svg_image('home/icons/logo.svg', alt_text: 'PlaceCal'))
    elsif logo_url
      logo_path = Rails.public_path.join(logo_url.delete_prefix('/'))
      if /\.svg$/i.match?(logo_url) && File.exist?(logo_path)
        raw(safe(File.read(logo_path)))
      else
        image_tag(logo_url, alt: @site.name)
      end
    else
      raw(view_context.svg_image('header.svg', alt_text: 'PlaceCal'))
    end
  end

  def render_site_name
    if @site&.default_site?
      if request.path == '/'
        h1(class: 'sr-only') { 'PlaceCal' }
      else
        h2(class: 'sr-only') { 'PlaceCal' }
      end
    else
      h2(class: 'sr-only') { @site&.name }
      p(class: 'sr-only') { 'The Community Calendar' }
    end
  end

  def render_menu
    # FIXME: arbitrary values
    li_css_class = [
      'text-center',
      ('max-md:bg-tertiary max-md:py-3' if @site&.default_site?),
      ('py-4 max-md:bg-text transition-none max-md:transition-colors duration-300 max-md:hover:bg-tertiary md:max-lg:justify-evenly md:max-lg:grow' unless @site&.default_site?)
    ]
    # active_link_to is defined in app/helpers/application_helper.rb and wraps link_to, which is not a phlex component
    a_css_class = [
      'with-reset with-no-sass text-background text-base after:block after:mx-auto after:w-10',
      ('font-semibold after:h-[3px] after:mt-[-4px] after:transition-colors after:duration-300 md:hover:after:bg-primary md:[&:is(.active)]:after:bg-primary lg:after:mt-[2px] lg:after:h-[3.5px] lg:hover:after:bg-tertiary lg:[&:is(.active)]:after:bg-tertiary' if @site&.default_site?),
      ('font-extra-bold tracking-wide uppercase max-md:text-xl md:after:h-[4px] md:hover:after:bg-primary md:[&:is(.active)]:after:bg-primary lg:text-text' unless @site&.default_site?)
    ].join(' ')
    nav(class: [
          'nav header__menu row-start-2 col-start-1 col-span-2 flex flex-col md:flex-row -mx-6 justify-evenly h-auto transition-[display,height,margin-top,padding-block] duration-300 overflow-clip',
          ('pt-4 gap-[0.175rem] md:max-lg:[&:is(.is-hidden)]:py-0 md:max-lg:[&:is(.is-hidden)]:mt-[1.1rem] md:flex-row md:max-lg:bg-tertiary md:gap-8 md:pt-[0.8rem] md:pb-4 md:mt-6 md:bg-tertiar lg:row-start-1 lg:col-start-2 lg:col-span-1 max-lg:[&:is(.is-hidden)]:h-0 lg:justify-end lg:mx-0 lg:mt-1.5 lg:py-0' if @site&.default_site?),
          ('gap-1 mt-4 md:-mx-6 max-md:[&:is(.is-hidden)]:h-0 max-md:[&:is(.is-hidden)]:pb-0 max-md:bg-tertiary md:max-lg:bg-text max-md:pb-1 lg:row-start-1 lg:col-start-2 lg:col-span-1 lg:gap-8 lg:m-0 md:max-lg:px-2' unless @site&.default_site?)

        ], data: { mobile_menu_target: 'menu' }) do
      ul(class: 'contents') do
        # FIXME: turbolinks was unset on the first navigation item. assuming that turbolinks means `preload on hover`, it does that on all nav links regardless of the setting
        @navigation.each do |link_text, link_path|
          li(class: li_css_class) { active_link_to(link_text, link_path, data: { turbolinks: false }, base_css_class: a_css_class) }
        end
      end
    end
  end

  def render_toggle
    button(type: 'button', class: [
             'header__toggle row-start-1 col-start-2 flex gap-2 ms-auto me-1.5 items-center text-background md:me-4',
             ('lg:hidden' if @site&.default_site?),
             ('md:hidden' unless @site&.default_site?)
           ], data: { action: 'click->mobile-menu#toggle', turbo: 'false' }) do
      span(class: 'text-base font-semibold') { 'Menu' } if @site&.default_site?
      raw(view_context.icon(:misc_menu, size: nil, css_class: 'size-[33px] fill-secondary'))
    end
  end
end
