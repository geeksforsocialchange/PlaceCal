# frozen_string_literal: true

# Cascading neighbourhood filter for the directory site.
#
# Renders one styled dropdown per geographic level (region > county > district >
# ward) using the same CustomSelect widget as the other filters, so the open
# dropdown looks identical. Every level submits under the `neighbourhood` name;
# the `neighbourhood-cascade` Stimulus controller disables the other levels on
# change so only the one you touched is applied. Selecting any level filters its
# whole subtree, and the page re-renders the levels for the new selection.
class Components::Directory::NeighbourhoodCascade < Components::Directory::Base
  prop :tree, _Interface(:each)
  prop :selected, _Nilable(String), default: nil
  prop :label_text, String, default: 'Neighbourhood'

  def view_template
    div(
      class: 'basis-full md:basis-auto md:shrink-0',
      data: { controller: 'neighbourhood-cascade', action: 'change->neighbourhood-cascade#onChange' }
    ) do
      label(class: 'block allcaps-label text-tertiary mb-1') { @label_text }
      div(class: 'flex flex-wrap gap-2') do
        cascade_levels.each do |level|
          div(class: 'flex-1 min-w-0 md:flex-none md:w-56') do
            Directory::CustomSelect(
              name: 'neighbourhood',
              label_text: nil,
              options: level[:options],
              selected: level[:selected],
              include_blank: level[:include_blank],
              default_label: level[:default_label]
            )
          end
        end
      end
    end
  end

  private

  # One dropdown per level along the selected path, plus the next level so you
  # can keep drilling. The first level clears the filter; deeper levels offer an
  # "All of <parent>" option that filters by the parent's whole subtree.
  def cascade_levels
    roots = @tree.to_a
    path = find_path(roots, @selected)
    levels = []
    nodes = roots
    depth = 0

    loop do
      selected_node = path[depth]
      levels << level_for(nodes, selected_node, path, depth)
      break unless selected_node

      nodes = selected_node[:children] || []
      break if nodes.empty?

      depth += 1
    end

    levels
  end

  def level_for(nodes, selected_node, path, depth)
    if depth.zero?
      {
        options: nodes.map { |n| option_for(n) },
        selected: selected_node && selected_node[:id].to_s,
        include_blank: true,
        default_label: t('directory.filters.all_neighbourhoods')
      }
    else
      parent = path[depth - 1]
      {
        options: [{ id: parent[:id], name: t('directory.filters.all_of', name: parent[:name]) }] + nodes.map { |n| option_for(n) },
        selected: (selected_node || parent)[:id].to_s,
        include_blank: false,
        default_label: nil
      }
    end
  end

  def option_for(node)
    { id: node[:id], name: node[:name], count: node[:count] }
  end

  # Chain of nodes from a root down to the node with the given id.
  def find_path(nodes, target_id)
    return [] if target_id.blank?

    nodes.each do |node|
      return [node] if node[:id].to_s == target_id.to_s

      child_path = find_path(node[:children] || [], target_id)
      return [node, *child_path] if child_path.any?
    end
    []
  end
end
