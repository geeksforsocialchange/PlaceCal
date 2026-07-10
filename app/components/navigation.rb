# frozen_string_literal: true

# Tailwind classes are generally [ base, directory, partner site]. each section may be split into targets and breakpoints depending on complexity

class Components::Navigation < Components::Base
  prop :navigation, Array # Array of tuples of [name, URL]
  prop :site, _Nilable(::Site), default: nil

  def view_template
    header(class: [
             'header grid grid-cols-[1fr_auto] items-center',
             *(
               if @site.nil?
                 ['header__default container-public py-6 bg-background border-b border-rules']
               else
                 ['header__partner mx-4 pt-4', 'lg:py-4 lg:mx-12 lg:py-6']
               end
             )
           ], data: { controller: 'mobile-menu' }) do
      render_branding
      render_toggle
      render_menu
    end
  end

  private

  def render_branding
    link_to(root_path, class: [
              'header__branding row-start-1 col-start-1 ',
              ("header__branding--#{@site.slug}" if @site&.slug.presence),
              # svg/img classes are here because partner svgs are inlined with File.read
              '[&>svg,&>img]:object-contain [&>svg,&>img]:max-w-full [&>svg,&>img]:max-h-full',
              *(if @site.nil?
                  ['w-32 h-10 md:w-42 md:h-12']
                else
                  ['w-42 h-12']
                end)
            ]) do
      render_logo
      render_site_name
    end
  end

  def render_logo
    logo_url = @site&.logo&.url.presence
    if @site.nil?
      raw(view_context.svg_image('home/icons/logo-dark.svg', alt_text: 'PlaceCal'))
    elsif logo_url
      logo_path = Rails.public_path.join(logo_url.delete_prefix('/'))
      if /\.svg$/i.match?(logo_url) && File.exist?(logo_path)
        raw(safe(File.read(logo_path)))
      else
        image_tag(logo_url, alt: @site&.name)
      end
    else
      raw(view_context.svg_image('header.svg', alt_text: 'PlaceCal'))
    end
  end

  def render_site_name
    if @site.nil?
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
    nav(class: menu_nav_classes, data: { mobile_menu_target: 'menu' }) do
      ul(class: 'contents') do
        @navigation.each do |link_text, link_path|
          li(class: menu_li_classes) { active_link_to(link_text, link_path, data: { turbolinks: false }, base_css_class: menu_link_classes, active_css_class: menu_active_classes) }
        end
        render_join_button if @site.nil?
      end
    end
  end

  # TODO: Change to join.placecal.org once the join flow is live
  def render_join_button
    li(class: 'text-center max-md:py-3') do
      link_to('Join us', get_in_touch_path, class: 'inline-flex items-center rounded-full bg-secondary px-4 py-1.5 text-detail font-bold no-underline hover:brightness-110 transition-all', style: 'color: #43392f')
    end
  end

  def menu_li_classes
    [
      'text-center',
      *(if @site.nil?
          ['max-md:bg-home-background max-md:py-3']
        else
          [
            'py-4 duration-300 transition-none',
            'max-md:bg-foreground max-md:transition-colors max-md:hover:bg-tertiary',
            'md:max-lg:justify-evenly md:max-lg:grow'
          ]
        end)
    ]
  end

  def menu_link_classes
    [
      'with-reset with-no-sass text-base',
      'after:block after:mx-auto after:w-10',
      *(if @site.nil?
          [
            'text-foreground font-bold',
            'after:h-[3.5px] after:mt-0.5 after:transition-colors after:duration-300',
            'hover:after:bg-foreground'
          ]
        else
          [
            'text-background font-extra-bold tracking-wide uppercase',
            'max-md:text-xl',
            'md:after:h-1 md:hover:after:bg-primary',
            'lg:text-foreground'
          ]
        end)
    ].join(' ')
  end

  def menu_active_classes
    (@site.nil? ? 'after:bg-foreground' : 'md:after:bg-primary')
  end

  def menu_nav_classes
    [
      'nav header__menu row-start-2 col-start-1 col-span-2 flex flex-col justify-evenly is-hidden',
      'h-auto overflow-clip transition-[display,height,margin-top,padding-block] duration-300',
      'md:flex-row',
      *(if @site.nil?
          [
            # negative margins must match container-public's padding (0.75rem, then 1.25rem at md)
            # so the dropdown sits flush to the edges without overflowing the viewport; lg:mx-0 below
            '-mx-3 md:-mx-5',
            'pt-4 gap-0.5  lg:row-start-1 lg:col-start-2 lg:col-span-1',
            'md:flex-row md:gap-8 md:pt-3 md:pb-4 md:mt-6',
            'md:max-lg:[&:is(.is-hidden)]:py-0 md:max-lg:[&:is(.is-hidden)]:mt-4.5 md:max-lg:bg-home-background',
            'max-lg:[&:is(.is-hidden)]:h-0',
            'lg:justify-end lg:items-baseline lg:mx-0 lg:mt-1.5 lg:py-0'
          ]
        else
          [
            '-mx-6 gap-1 mt-4',
            'max-md:pb-1 max-md:bg-tertiary max-md:[&:is(.is-hidden)]:h-0 max-md:[&:is(.is-hidden)]:pb-0',
            'md:-mx-6',
            'md:max-lg:px-2 md:max-lg:bg-foreground',
            'lg:row-start-1 lg:col-start-2 lg:col-span-1 lg:gap-8 lg:m-0'
          ]
        end)
    ]
  end

  def render_toggle
    button(type: 'button', class: [
             'header__toggle row-start-1 col-start-2 flex gap-2 ms-auto me-1.5 items-center',
             (@site.nil? ? 'text-foreground' : 'text-background'),
             'md:me-4',
             *(if @site.nil?
                 ['lg:hidden']
               else
                 ['md:hidden']
               end)
           ], data: { action: 'click->mobile-menu#toggle', turbo: 'false' }) do
      span(class: 'text-base font-semibold') { 'Menu' } if @site.nil?
      raw(view_context.icon(:misc_menu, size: nil, css_class: 'size-8 fill-secondary'))
    end
  end
end
