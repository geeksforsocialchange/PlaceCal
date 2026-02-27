# frozen_string_literal: true

require 'yaml'

class Components::CaseStudy < Components::Base
  prop :partner_key, String

  def after_initialize
    partner_info = YAML.load_file(
      File.join(__dir__, 'case_study_data.yml')
    )[@partner_key]

    @partner = partner_info['partner']
    @logo_src = partner_info['logo_src']
    @image_src = partner_info['image_src']
    @image_alt = partner_info['image_alt']
    @partner_url = partner_info['partner_url']
    @link_url = partner_info['link_url']
    @description = partner_info['description']
    @pull_quote = partner_info['pull_quote']
  end

  def view_template
    section(class: 'case_study__section--outer') do
      section(class: 'case_study__section--inner case_study__round-border--top') do
        h3(class: 'case_study__title') { 'Curated Calendars' }
        image_tag(@image_src, alt: @image_alt, class: 'case_study__img')
        div(class: 'case_study__section-top') do
          PullQuote(source: '', quote_context: '', options: { light_mode: true }) do
            @pull_quote
          end
        end
      end
      section(class: 'case_study__section--inner case_study__round-border--bottom') do
        div(class: 'case_study__row') do
          div(class: 'case_study__logo_column') do
            a(href: @partner_url, class: 'case_study__anchor') do
              image_tag(@logo_src, alt: "#{@partner} logo", class: 'case_study__img--logo')
            end
            div(class: 'case_study__column case_study__buttons_column') do
              LinkBtnLrg(link_url: @partner_url, color: 'pink') { 'Find out more' }
              LinkBtnLrg(link_url: @link_url, color: 'pink') { 'Find your PlaceCal' }
            end
          end
          div(class: 'case_study__description_column') do
            @description.each do |d|
              p { d }
            end
          end
        end
      end
    end
  end
end
