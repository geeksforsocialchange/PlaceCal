# frozen_string_literal: true

class Components::Directory::PartnershipCard < Components::Directory::Base
  prop :partnership, ::Site

  def view_template
    a(href: partnership_path(@partnership),
      class: [
        'flex flex-col rounded-[1rem] overflow-hidden no-underline',
        'text-foreground hover:shadow-lg transition-shadow min-h-[200px]'
      ].join(' ')) do
      render_head
      render_body
    end
  end

  private

  def render_head
    div(class: 'bg-foreground text-background px-5 py-4 flex justify-between items-start') do
      div do
        div(class: 'text-[0.7rem] font-extra-bold uppercase tracking-wide text-background/80 mb-1') { 'Partnership' }
        h3(class: 'font-serif font-regular text-[1.3rem] leading-tight text-background') { @partnership.name }
      end
      span(class: 'text-background/70 text-lg') { safe('&rarr;') }
    end
  end

  def render_body
    div(class: 'bg-home-background-3 px-5 py-4 flex-1') do
      div(class: 'flex flex-wrap gap-1.5 mb-2') do
        if @partnership.primary_neighbourhood
          span(class: 'inline-flex items-center gap-1 bg-rules-dark text-foreground text-[0.72rem] font-bold rounded-full px-2.5 py-0.5') do
            plain @partnership.primary_neighbourhood.name
          end
        end
        span(class: 'inline-flex items-center gap-1 bg-primary-light text-foreground text-[0.72rem] font-bold rounded-full px-2.5 py-0.5') do
          plain "#{@partnership.partners_count} #{'partner'.pluralize(@partnership.partners_count)}"
        end
      end
      p(class: 'text-[0.88rem] leading-relaxed text-tertiary line-clamp-3') { @partnership.description } if @partnership.description.present?
    end
  end
end
