# frozen_string_literal: true

class Components::PartnershipCard < Components::Base
  prop :site, ::Site

  def after_initialize
    url_concatenator = @site.url[-1] == '/' ? '' : '/'
    @site_name = @site.name
    @site_tagline = @site.tagline
    @image_src = @site.logo.url
    @link_to = "#{@site.url}#{url_concatenator}events"
  end

  def view_template
    div(class: 'text-center w-full') do
      div(class: 'bg-home-green rounded-[1.11rem] h-24 p-4') do
        img(class: 'w-40', src: @image_src, alt: "#{@site_name} logo")
      end
      p(class: 'text-home-background-3 px-8 tp:min-h-20') { @site_tagline }
      link_to("#{@site_name} calendar", @link_to,
              class: 'flex items-center flex-col justify-center font-bold no-underline w-full rounded-[3rem] bg-home-background-3 p-2 tp:h-[4.5rem] tp:p-4 transition duration-300 hover:bg-home-pink hover:text-home-background hover:outline-base-text')
    end
  end
end
