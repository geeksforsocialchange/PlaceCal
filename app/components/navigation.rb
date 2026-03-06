# frozen_string_literal: true

class Components::Navigation < Components::Base
  prop :navigation, Array # Array of tuples of [name, URL]
  prop :site, _Nilable(::Site), default: nil

  def view_template
    header_class = @site&.default_site? ? 'header__default' : 'header__partner'
    header(class: "header #{header_class}", data: { controller: 'mobile-menu' }) do
      render_branding
      render_menu
      render_toggle
    end
  end

  private

  def render_branding
    link_to(root_path, class: "header__branding header__branding--#{@site&.slug}") do
      render_logo
      render_site_name
    end
  end

  def render_logo
    logo_url = @site&.logo&.url.presence

    if @site&.default_site?
      raw(view_context.svg_image('home/icons/logo.svg', alt_text: 'PlaceCal'))
    elsif logo_url
      if /\.svg$/i.match?(logo_url)
        render_uploaded_svg(logo_url)
      else
        image_tag(logo_url, alt: @site.name)
      end
    else
      raw(view_context.svg_image('header.svg', alt_text: 'PlaceCal'))
    end
  end

  def render_uploaded_svg(logo_url)
    file_path = Rails.public_path.join(logo_url.delete_prefix('/'))
    if File.exist?(file_path)
      raw(safe(File.read(file_path)))
    else
      image_tag(logo_url, alt: @site.name)
    end
  end

  def render_site_name
    if @site&.default_site?
      if request.path == '/'
        h1 { 'PlaceCal' }
      else
        h2 { 'PlaceCal' }
      end
    else
      h2 { @site&.name }
      p { 'The Community Calendar' }
    end
  end

  def render_menu
    nav(class: 'nav header__menu', data: { mobile_menu_target: 'menu' }) do
      ul do
        li { active_link_to('Home', root_path) }
        @navigation.each do |link_text, link_path|
          li { active_link_to(link_text, link_path, data: { turbolinks: false }) }
        end
      end
    end
  end

  def render_toggle
    button(type: 'button', class: 'header__toggle', data: { action: 'click->mobile-menu#toggle', turbo: 'false' }) do
      span { 'Menu' }
      raw(view_context.icon(:misc_menu, size: nil))
    end
  end
end
