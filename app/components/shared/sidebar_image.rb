# frozen_string_literal: true

# The image at the top of a partner or event page's side column
class Components::Shared::SidebarImage < Components::Base
  LOOK = {
    site: { root: 'text-center my-6 print:hidden', image: 'max-w-full' },
    directory: { root: 'rounded-card overflow-hidden mt-4', image: 'block w-full' }
  }.freeze

  prop :src, String
  prop :alt, String
  prop :srcset, _Nilable(String), default: nil
  prop :layout, _Union(*LOOK.keys), default: :site
  prop :attributes, Hash, :**

  def view_template
    look = LOOK[@layout]
    div(class: [look[:root], @attributes[:class]].compact.join(' '), **@attributes.except(:class)) do
      img(src: @src, srcset: @srcset, alt: @alt, decoding: 'async', class: look[:image])
    end
  end
end
