# frozen_string_literal: true

# A row of secondary actions below a page's main content: back-to-index,
# add-to-calendar, organiser or previous/next links and the like (#3368).
# A generic slot any theme can restyle: core supplies only the semantic
# .page-actions / .page-actions__link hooks, given a minimal default look in
# app/tailwind/public/_components.css (near where .meta gets its own,
# app/assets/stylesheets/components/meta.scss) so a themeless site still
# reads as a centred list of links.
class Components::PageActions < Components::Base
  # [label, href, options] triples. `options` (data:, rel:, download:, ...)
  # passes straight through to link_to, alongside the component's own class.
  prop :links, Array, default: -> { [] }

  def view_template
    return if @links.empty?

    nav(class: 'page-actions', aria_label: t('page_actions.label')) do
      ul(class: 'reset') do
        @links.each do |label, href, options|
          li { link_to(label, href, (options || {}).merge(class: 'page-actions__link')) }
        end
      end
    end
  end
end
