# frozen_string_literal: true

class Components::Shared::OnlineEventButton < Components::Base
  prop :online_address, OnlineAddress
  # An indirect link only stands in for a missing webpage link.
  prop :has_webpage, _Boolean, default: false

  def view_template
    if @online_address.link_type.direct?
      UI::Button(variant: :outline, href: @online_address.url) { join_label }
    elsif !@has_webpage
      UI::Button(variant: :outline, href: @online_address.url) { t('events.show.visit_webpage') }
    end
  end

  private

  def join_label
    service = @online_address.service_name
    return t('events.show.join_meeting') unless service

    t(@online_address.stream? ? 'events.show.watch_on' : 'events.show.join_on', service:)
  end
end
