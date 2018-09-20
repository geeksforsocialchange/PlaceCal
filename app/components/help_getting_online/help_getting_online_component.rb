# frozen_string_literal: true

class HelpGettingOnlineComponent < MountainView::Presenter
  property :site

  def locations
    # TODO: refactor as one expression
    local = Place.joins(:turfs).where(turfs: { id: site.neighbourhoods })
    internet = Place.joins(:turfs).where(turfs: { slug: 'internet' })
    # Intersection of the two
    (local & internet).sort_by(&:name.downcase)
  end
end
