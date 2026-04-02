# frozen_string_literal: true

# TODO: break into home and partner variants. there are too many ternaries
class Components::Navigation < Components::Base
  prop :navigation, Array # Array of tuples of [name, URL]
  prop :site, _Nilable(::Site), default: nil

  def view_template
    css_class = @site&.default_site? ? 'header__default mx-3 py-6' : 'header__partner mx-4 py-4'
    header(class: "header grid grid-cols-[1fr_auto] items-center #{css_class}", data: { controller: 'mobile-menu' }) do
      render_branding
      render_toggle
      render_menu
    end
  end

  private

  def render_branding
    # FIXME: arbitrary values
    css_class = @site&.default_site? ? 'w-[148px] h-[44px]' : 'w-[187px] h-[55px]'
    # svg/img classes are here because partner svgs are inlined with File.read, which does not allow setting classes
    link_to(root_path, class: "header__branding header__branding--#{@site&.slug} row-start-1 col-start-1 [&>svg,&>img]:object-contain [&>svg,&>img]:max-w-full [&>svg,&>img]:max-h-full  #{css_class}") do
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
    nav_css_class = @site&.default_site? ? 'gap-[0.175rem] lg:row-start-1 lg:col-start-2 lg:col-span-1' : 'gap-1 mt-4 lg:row-start-1 lg:col-start-2 lg:col-span-1'
    li_css_class = "bg-tertiary text-center #{@site&.default_site? ? 'py-3 md:py-0' : 'py-4'}"
    a_css_class = "with-reset with-no-sass text-background text-base #{@site&.default_site? ? 'font-semibold' : 'font-extra-bold tracking-wide uppercase'}"
    nav(class: "nav header__menu row-start-2 col-start-1 col-span-2 flex flex-col md:flex-row  pt-4 -mx-6 justify-evenly h-auto transition-[display,height,margin-top,padding-block] duration-300 overflow-clip #{nav_css_class}", data: { mobile_menu_target: 'menu' }) do
      ul(class: 'contents') do
        # FIXME: turbolinks was unset on the first navigation item. assuming that turbolinks means `preload on hover`, it does that on all nav links regardless of the setting
        @navigation.each do |link_text, link_path|
          li(class: li_css_class) { active_link_to(link_text, link_path, data: { turbolinks: false }, base_css_class: a_css_class) }
        end
      end
    end
  end

  def render_toggle
    css_class = @site&.default_site? ? 'lg:hidden' : 'md:hidden'
    button(type: 'button', class: "header__toggle row-start-1 col-start-2 flex gap-2 ms-auto me-1.5 items-center text-background #{css_class}", data: { action: 'click->mobile-menu#toggle', turbo: 'false' }) do
      span(class: 'text-base font-semibold') { 'Menu' } if @site&.default_site?
      raw(view_context.icon(:misc_menu, size: nil, css_class: 'size-[33px] fill-secondary'))
    end
  end
end
