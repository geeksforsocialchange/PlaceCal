# frozen_string_literal: true

class Components::Navigation < Components::Base
  prop :navigation, Array
  prop :site, _Nilable(::Site), default: nil

  def view_template
    div(class: 'header', data: { controller: 'mobile-menu' }) do
      render_branding
      render_nav_menu
      render_toggle
    end
  end

  private

  def render_nav_menu
    nav(class: 'nav header__menu', data: { mobile_menu_target: 'menu' }, role: 'navigation') do
      ul do
        li { active_link_to('Home', root_path) }
        @navigation.each do |link_text, link_path|
          li { active_link_to(link_text, link_path, data: { turbolinks: false }) }
        end
      end
    end
  end

  def render_toggle
    a(href: '#', class: 'header__toggle', data: { action: 'click->mobile-menu#toggle', turbo: 'false' }) do
      raw safe(hamburger_svg)
    end
  end

  def render_branding
    if @site&.logo.present?
      div(
        class: "header__branding header__branding--#{@site.slug}",
        style: "background-image: url(#{image_url(@site.logo)})",
        role: 'banner'
      ) { branding_content }
    else
      div(class: 'header__branding', role: 'banner') { branding_content }
    end
  end

  def branding_content
    link_to(root_path) do
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
  end

  def hamburger_svg
    <<~SVG
      <svg viewBox="0 0 33 31" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
        <polygon class="svg__primary" points="0 5 33 5 33 0 0 0"></polygon>
        <polygon class="svg__primary" points="0 18 33 18 33 13 0 13"></polygon>
        <polygon class="svg__primary" points="0 31 33 31 33 26 0 26"></polygon>
      </svg>
    SVG
  end
end
