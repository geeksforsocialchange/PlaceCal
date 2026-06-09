# frozen_string_literal: true

# Cascading neighbourhood filter for the directory site.
#
# Renders a hidden `neighbourhood` field plus a container the
# `neighbourhood-cascade` Stimulus controller fills with linked selects, one per
# geographic level (region > county > district > ward). The preloaded tree comes
# from PartnersQuery#neighbourhood_tree, so no AJAX is needed; selecting a higher
# level filters its whole subtree.
class Components::Directory::NeighbourhoodCascade < Components::Directory::Base
  prop :tree, _Interface(:each)
  prop :selected, _Nilable(String), default: nil
  prop :label_text, String, default: 'Neighbourhood'

  def view_template
    div(
      class: 'min-w-0',
      data: {
        controller: 'neighbourhood-cascade',
        neighbourhood_cascade_tree_value: @tree.to_a.to_json,
        neighbourhood_cascade_selected_value: @selected.to_s
      }
    ) do
      label(class: 'block allcaps-label text-tertiary mb-1') { @label_text }
      input(
        type: 'hidden', name: 'neighbourhood', value: @selected,
        data: { neighbourhood_cascade_target: 'field' }
      )
      div(
        class: 'flex flex-wrap gap-2',
        data: { neighbourhood_cascade_target: 'selects' }
      )
    end
  end
end
