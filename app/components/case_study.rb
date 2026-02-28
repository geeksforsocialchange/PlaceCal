# frozen_string_literal: true

class Components::CaseStudy < Components::Base
  prop :partner, String
  prop :link_url, String
  prop :logo_src, String
  prop :image_alt, String
  prop :image_src, String
  prop :partner_url, String
  prop :pull_quote, String
  prop :description, Array

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
              a(href: @partner_url, class: 'link_btn_lrg link_btn_lrg--pink') { 'Find out more' }
              a(href: @link_url, class: 'link_btn_lrg link_btn_lrg--pink') { 'Find your PlaceCal' }
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
