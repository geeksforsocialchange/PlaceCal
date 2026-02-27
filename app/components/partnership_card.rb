# frozen_string_literal: true

class Components::PartnershipCard < Components::Base
  prop :site, _Any

  def after_initialize
    url_concatenator = @site.url[-1] == '/' ? '' : '/'
    @site_name = @site.name
    @site_tagline = @site.tagline
    @image_src = @site.logo.url
    @link_to = "#{@site.url}#{url_concatenator}events"
  end

  def view_template
    div(class: 'partnership_card') do
      div(class: 'partnership_card--logo') do
        img(class: 'partnership_card--image', src: @image_src, alt: "#{@site_name} logo")
      end
      p(class: 'partnership_card--summary') { @site_tagline }
      link_to("#{@site_name} calendar", @link_to, class: 'partnership_card--link')
    end
  end
end
