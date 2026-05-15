# frozen_string_literal: true

class Components::Directory::EventRow < Components::Directory::Base
  prop :event, _Interface(:summary, :dtstart)

  def view_template
    div(class: 'grid grid-cols-[64px_1fr] gap-3 items-start py-3 border-b-2 border-rules first:border-t-2') do
      render_date_badge
      render_details
    end
  end

  private

  def render_date_badge
    div(class: 'font-serif text-center bg-home-background-3 rounded-sm py-1.5 px-2') do
      div(class: 'text-2xl leading-none') { @event.dtstart.day.to_s }
      div(class: 'text-2xs uppercase tracking-wide text-tertiary font-sans font-bold mt-0.5') do
        plain @event.dtstart.strftime('%b')
      end
    end
  end

  def render_details
    div do
      div(class: 'font-extra-bold text-base mb-0.5') do
        link_to(@event.summary, event_path(@event), class: 'no-underline text-foreground hover:underline')
      end
      div(class: 'text-xs text-tertiary flex flex-wrap gap-x-3 gap-y-1') do
        span { plain fmt_time }
        if @event.place || @event.organiser
          partner = @event.place || @event.organiser
          span do
            link_to(partner.name.truncate(30), partner_path(partner),
                    class: 'text-foreground underline decoration-primary')
          end
        end
      end
    end
  end

  def fmt_time
    t = @event.dtstart
    t.strftime('%M') == '00' ? t.strftime('%l%P').strip : t.strftime('%l:%M%P').strip
  end
end
