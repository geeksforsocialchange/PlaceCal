# frozen_string_literal: true

# A news article as a single row for directory-styled lists: date badge,
# linked title and, optionally, a summary line and partner/area attribution.
# Named News* (not Article*) so the component namespace stays clear of the
# Article model.
class Components::Directory::NewsRow < Components::Directory::Base
  prop :article, ::Article
  # The partner page the row is shown on, so we don't repeat its name
  prop :context_partner, _Nilable(::Partner), default: nil
  # Area breadcrumb for the article's first partner (PartnersQuery.area_labels)
  prop :area, _Nilable(String), default: nil
  prop :summary, _Boolean, default: false

  def view_template
    div(class: 'grid grid-cols-[64px_1fr] gap-4 items-start py-3 border-b border-rules') do
      render_date_badge
      render_body
    end
  end

  private

  def render_date_badge
    date = @article.published_at
    div(class: 'font-serif text-center bg-home-background-3 rounded-lg py-1 px-2') do
      div(class: 'text-[1.7rem] leading-none font-regular tracking-tight') { date.day.to_s }
      div(class: 'font-sans text-2xs uppercase tracking-widest text-tertiary font-extra-bold mt-1') do
        plain date.strftime('%b %Y').upcase
      end
    end
  end

  def render_body
    div do
      div(class: 'font-bold text-lg leading-tight mb-1') do
        link_to(@article.title, news_path(@article),
                class: 'no-underline text-foreground hover:border-b-2 hover:border-primary',
                data: { turbo_frame: '_top' })
      end

      div(class: 'text-foreground leading-snug mt-1 line-clamp-2') { summary_text } if @summary && summary_text.present?

      div(class: 'flex flex-wrap gap-x-3 gap-y-0.5 text-sm text-tertiary mt-1') do
        render_meta_partners if attributed_partners.any?
        render_meta_area if @area.present?
      end
    end
  end

  def render_meta_partners
    span(class: 'inline-flex items-center gap-1') do
      render_icon(:partner)
      attributed_partners.each_with_index do |partner, index|
        plain ', ' if index.positive?
        link_to(partner.name.truncate(30), partner_path(partner),
                class: 'text-foreground underline decoration-primary decoration-2 underline-offset-2 hover:text-foreground/80',
                data: { turbo_frame: '_top' })
      end
    end
  end

  def render_meta_area
    span(class: 'inline-flex items-center gap-1') do
      render_icon(:event_place)
      plain @area
    end
  end

  def render_icon(name)
    raw(view_context.icon(name, size: nil, css_class: 'w-3.5 h-3.5 text-tertiary opacity-55 shrink-0'))
  end

  def attributed_partners
    @attributed_partners ||= @article.partners.reject { |partner| partner == @context_partner }
  end

  def summary_text
    @summary_text ||= view_context.article_summary_text(@article)
  end
end
