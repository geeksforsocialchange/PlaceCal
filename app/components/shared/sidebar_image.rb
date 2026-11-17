# frozen_string_literal: true

# The image at the top of a partner or event page's side column
class Components::Shared::SidebarImage < Components::Base
  LOOK = {
    site: { root: 'text-center print:hidden', image: 'max-w-full rounded-card border-2 border-rules' },
    directory: { root: 'rounded-card overflow-hidden border-2 border-rules', image: 'block w-full' }
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
