# frozen_string_literal: true

# Progressive "show more" disclosure: renders the items in batches, each batch
# behind a <details> whose summary reveals the next batch (and, recursively,
# another toggle for the batch after that). Each item is rendered by the block
# passed to the component.
#
# @example
#   Directory::OverflowToggle(items: extra_events, label_key: "directory.partners.show.show_more_events") do |event|
#     Directory::EventRow(event: event)
#   end
class Components::Directory::OverflowToggle < Components::Directory::Base
  prop :items, _Interface(:each)
  # i18n key for the summary label; receives a `count:` interpolation.
  prop :label_key, String
  prop :batch_size, Integer, default: 10

  def view_template(&block)
    @render_item = block
    render_batch(@items.to_a)
  end

  private

  def render_batch(remaining)
    return if remaining.empty?

    batch = remaining.first(@batch_size)
    details(class: 'group') do
      summary(class: 'list-none pt-3 border-t border-rules cursor-pointer [&::-webkit-details-marker]:hidden') do
        span(class: 'inline-flex items-center gap-1.5 text-sm font-bold text-foreground group-open:hidden') do
          plain t(@label_key, count: [@batch_size, remaining.size].min)
          span(class: 'text-tertiary') { safe('&#9660;') }
        end
      end
      batch.each { |item| @render_item.call(item) }
      render_batch(remaining.drop(@batch_size))
    end
  end
end
