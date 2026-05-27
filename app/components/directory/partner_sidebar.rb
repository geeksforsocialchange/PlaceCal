# frozen_string_literal: true

class Components::Directory::PartnerSidebar < Components::Directory::Base
  prop :partner, ::Partner
  prop :containing_sites, _Interface(:each), default: -> { [] }

  def view_template
    div(class: 'flex flex-col gap-4') do
      render_image if @partner.read_attribute(:image).present?
      render_partnerships if Array(@containing_sites).any?
      render ContactDetails.new(partner: @partner, variant: :tailwind)
      render_opening_times if @partner.human_readable_opening_times.any?
      render_categories if @partner.categories.any?
      render_neighbourhood if @partner.address&.neighbourhood
      render_share
    end
  end

  private

  def render_image
    div(class: 'rounded-card overflow-hidden') do
      img(
        src: @partner.image.standard.url,
        srcset: "#{@partner.image.standard.url} 1x, #{@partner.image.retina.url} 2x",
        alt: @partner.name,
        class: 'w-full object-cover'
      )
    end
  end

  def render_partnerships
    count = Array(@containing_sites).size
    div(class: 'rounded-card overflow-hidden') do
      div(class: 'bg-foreground px-4 py-3', style: 'color: var(--color-background)') do
        div(class: 'allcaps-label mb-0.5 opacity-80') { 'Part of' }
        div(class: 'font-serif text-lg') { "#{count} #{'partnership'.pluralize(count)}" }
      end
      div(class: 'bg-home-background-3 px-4 py-3') do
        div(class: 'text-xs text-tertiary mb-3') do
          plain "You can find #{@partner.name} on these local PlaceCal sites:"
        end
        Array(@containing_sites).each do |site_record|
          a(href: "https://#{site_record.slug}.placecal.org",
            class: 'flex items-center justify-between py-2 no-underline text-foreground hover:bg-background/50 transition-colors rounded px-1') do
            div do
              div(class: 'font-extra-bold text-sm') { site_record.name }
              div(class: 'text-xs text-tertiary') do
                plain site_record.primary_neighbourhood&.name if site_record.primary_neighbourhood
              end
            end
            span(class: 'text-tertiary') { safe('&#8599;') }
          end
        end
      end
    end
  end

  def render_opening_times
    times = @partner.human_readable_opening_times
    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      h3(class: 'allcaps-label text-tertiary mb-3') { 'Opening times' }
      ul(class: 'text-sm text-foreground space-y-1 list-none pl-0') do
        times.each { |slot| li { slot } }
      end
    end
  end

  def render_categories
    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      h3(class: 'allcaps-label text-tertiary mb-2') { 'Categories' }
      div(class: 'flex flex-wrap gap-1.5') do
        @partner.categories.each do |cat|
          a(href: partners_path(category: cat.id),
            class: 'inline-flex items-center bg-primary text-foreground text-2xs font-bold rounded-full px-2.5 py-0.5 no-underline hover:brightness-110 transition-colors') do
            plain cat.name
          end
        end
      end
    end
  end

  def render_neighbourhood
    neighbourhood = @partner.address.neighbourhood
    path = neighbourhood.path

    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      h3(class: 'allcaps-label text-tertiary mb-2') { 'Neighbourhood' }
      div(class: 'flex flex-wrap items-center gap-1 text-sm') do
        path.each_with_index do |ancestor, i|
          span(class: 'text-tertiary mx-0.5') { safe('&rsaquo;') } if i.positive?
          if ancestor == neighbourhood
            span(class: 'font-extra-bold text-foreground') { ancestor.name }
          else
            span(class: 'text-foreground') { ancestor.name }
          end
        end
      end
    end
  end

  def render_share
    div(class: 'rounded-card bg-home-background-3 px-4 py-4') do
      div(class: 'allcaps-label text-tertiary mb-3') { 'Share & subscribe' }

      div do
        a(href: "https://placecal.org/partners/#{@partner.slug}",
          class: 'font-mono text-sm text-foreground break-all no-underline hover:underline hover:decoration-primary') do
          plain "placecal.org/partners/#{@partner.slug}"
        end
      end
      div(class: 'mt-3') do
        a(href: partner_url(@partner, protocol: :webcal, format: :ics),
          class: 'inline-flex items-center gap-1.5 text-sm font-bold text-foreground no-underline hover:underline hover:decoration-primary') do
          raw(safe('<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>'))
          plain 'Subscribe via iCal'
        end
      end
    end
  end
end
