# frozen_string_literal: true

# The placecal.org and join footer: brand column, link columns, then the GFSC strip.
class Components::Shared::Footer < Components::Base
  prop :tagline, String
  prop :logo_alt, String
  # [[heading, [[label, href], ...]], ...]
  prop :columns, _Array(Array)

  def view_template(&brand_extra)
    footer(class: 'bg-home-background border-t-5 border-rules mt-16 pt-10 pb-6 print:hidden') do
      div(class: 'container-public grid grid-cols-1 md:grid-cols-footer gap-8') do
        render_brand(&brand_extra)
        @columns.each { |title, links| render_column(title, links) }
      end
      div(class: 'container-public mt-6 pt-5 border-t-2 border-rules text-sm text-tertiary font-serif', data_nosnippet: true) do
        Shared::Impressum()
      end
    end
  end

  private

  def render_brand(&)
    div do
      image_tag('home/icons/logo-dark.svg', class: 'h-10 mb-4', alt: @logo_alt, width: 127, height: 40)
      div(class: 'font-serif text-base text-tertiary leading-relaxed max-w-(--width-search)') { @tagline }
      yield if block_given?
    end
  end

  def render_column(title, links)
    div do
      UI::Kicker(as: :h2, tone: :foreground) { title }
      ul(class: 'list-none space-y-1') do
        links.each do |label, href|
          li { UI::Link(href:, variant: :quiet, class: 'font-serif text-detail') { label } }
        end
      end
    end
  end
end
