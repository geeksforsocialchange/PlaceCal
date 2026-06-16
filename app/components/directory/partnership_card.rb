# frozen_string_literal: true

class Components::Directory::PartnershipCard < Components::Directory::Base
  prop :partnership, ::Site

  def view_template
    a(href: partnership_path(@partnership),
      class: [
        'flex flex-col rounded-card overflow-hidden no-underline break-inside-avoid mb-4',
        'text-foreground hover:shadow-lg transition-shadow min-h-50'
      ].join(' ')) do
      render_head
      render_body
    end
  end

  private

  def render_head
    div(class: 'bg-foreground text-background px-5 py-4 flex justify-between items-start') do
      div do
        div(class: 'text-2xs font-extra-bold uppercase tracking-wide text-background/80 mb-1') { t('directory.partnerships.card.kicker') }
        div(class: 'font-serif font-regular text-card leading-tight text-background') { @partnership.name }
      end
      span(class: 'text-background/70 text-lg') { safe('&rarr;') }
    end
  end

  def render_body
    div(class: 'bg-home-background-3 px-5 py-4 flex-1') do
      div(class: 'flex flex-wrap gap-1.5 mb-2') do
        if @partnership.primary_neighbourhood
          span(class: 'badge gap-1 bg-rules-dark text-foreground') do
            raw(view_context.icon(:neighbourhood, size: nil, css_class: 'w-3 h-3'))
            plain @partnership.primary_neighbourhood.name
          end
        end
        span(class: 'badge gap-1 bg-primary-light text-foreground') do
          raw(view_context.icon(:partner, size: nil, css_class: 'w-3 h-3'))
          plain "#{@partnership.partners_count} #{Partner.model_name.human(count: @partnership.partners_count).downcase}"
        end
      end
      div(class: 'text-detail leading-relaxed text-tertiary line-clamp-3') { @partnership.description } if @partnership.description.present?
    end
  end
end
