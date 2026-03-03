# frozen_string_literal: true

class Views::Collections::Show < Views::Base
  prop :collection, Collection, reader: :private
  prop :site, Site, reader: :private
  prop :events, Hash, reader: :private

  def view_template
    content_for(:title) { collection.name }
    content_for(:description) { collection.description }
    content_for(:permalink) { collection.permalink }
    if collection.image?
      content_for(:image) { image_url(collection.image.standard.url) }
      content_for(:image_alt) { "Image for #{collection.name}" }
    end

    Hero(collection.name, site.tagline)

    div(class: 'c c--lg-space-after') do
      Breadcrumb(trail: [[collection.name, collection.named_route]], site_name: site.name)

      hr

      render_collection_details
      hr
      render_events
    end
  end

  private

  def render_collection_details
    div(class: 'g g--collection') do
      div(class: 'gi gi__3-5') do
        # Description placeholder - commented out in original ERB
      end
      div(class: 'gi gi__2-5 gi--image') do
        if collection.image?
          img(
            src: collection.image.standard.url,
            srcset: "#{collection.image.standard.url} 1x, #{collection.image.retina.url} 2x",
            alt: "Image for #{collection.name}"
          )
        end
      end
    end
  end

  def render_events
    EventList(
      events: events,
      primary_neighbourhood: site.primary_neighbourhood,
      show_neighbourhoods: site.show_neighbourhoods?,
      badge_zoom_level: site.badge_zoom_level&.to_s,
      site_tagline: site.tagline
    )
  end
end
