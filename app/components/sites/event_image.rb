# frozen_string_literal: true

class Components::Sites::EventImage < Components::Base
  theme_scope :event_image,
              parts: {
                root: 'The event\'s image from its source, beside the description. Only when the event has one.',
                image: 'The image itself, the column\'s full width at its own shape, never cropped.'
              },
              tokens: %i[--radius-card]

  prop :src, String
  prop :alt, String

  # Posters often carry the event's details as text, so the image is never cropped
  def view_template
    figure(**part(:root, class: 'rounded-card overflow-hidden')) do
      img(src: @src, alt: @alt, decoding: 'async', **part(:image, class: 'block w-full h-auto'))
    end
  end
end
