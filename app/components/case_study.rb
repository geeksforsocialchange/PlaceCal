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
    section(class: 'rounded-[1.11rem]') do
      section(class: 'bg-home-background-3 pb-4 relative rounded-t-[1.11rem]') do
        h3(class: 'font-sans text-[1.8rem] tp:text-[2.2rem] font-normal mx-auto my-8 max-w-[25ch] pt-8 text-center') { 'Curated Calendars' }
        image_tag(@image_src, alt: @image_alt, class: 'aspect-[2/1] bg-[#040f39] rounded-t-[1.11rem] tl:rounded-[1.11rem] object-cover')
        div(class: 'bg-base-background rounded-t-[1.11rem] p-8 tp:p-4 relative tl:absolute tl:bottom-0 tl:left-0 tl:right-0 tl:px-8 dt:px-4') do
          PullQuote(source: '', quote_context: '', options: { light_mode: true }) do
            @pull_quote
          end
        end
      end
      section(class: 'bg-home-background-3 pb-4 relative rounded-b-[1.11rem]') do
        div(class: 'flex flex-col tl:flex-row items-center gap-0 tl:gap-8 mx-auto max-w-[860px] px-8 py-4 dt:px-4 dt:pb-8') do
          div(class: 'flex flex-row flex-wrap tl:flex-col items-center tl:items-start gap-x-8 gap-y-4 tl:gap-4 justify-between tl:justify-start tl:flex-1 my-4 w-full tp:flex-nowrap') do
            a(href: @partner_url, class: 'max-tp:flex-1') do
              image_tag(@logo_src, alt: "#{@partner} logo", class: 'max-w-[350px] min-w-[200px] p-2 w-full')
            end
            div(class: 'flex flex-col gap-7 justify-start flex-1 w-full') do
              a(href: @partner_url, class: 'rounded-[3rem] font-bold outline-offset-2 py-1 px-6 text-center no-underline whitespace-nowrap transition-[300ms] bg-home-pink outline outline-2 outline-home-pink hover:bg-base-text hover:text-home-background hover:outline-base-text') { 'Find out more' }
              a(href: @link_url, class: 'rounded-[3rem] font-bold outline-offset-2 py-1 px-6 text-center no-underline whitespace-nowrap transition-[300ms] bg-home-pink outline outline-2 outline-home-pink hover:bg-base-text hover:text-home-background hover:outline-base-text') { 'Find your PlaceCal' }
            end
          end
          div(class: 'flex-[3]') do
            @description.each do |d|
              p { d }
            end
          end
        end
      end
    end
  end
end
