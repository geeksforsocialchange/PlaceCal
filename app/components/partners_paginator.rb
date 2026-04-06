# frozen_string_literal: true

class Components::PartnersPaginator < Components::Base
  prop :page_letter_ranges, Array
  prop :current_page, Integer
  prop :filter_params, Hash, default: -> { {} }

  def view_template
    nav(class: 'partners-paginator', aria_label: 'Partner pagination') do
      render_page_nav
    end
  end

  private

  def render_page_nav
    div(class: 'partners-paginator__pages') do
      @page_letter_ranges.each do |range|
        label = page_label(range)
        if range[:page] == @current_page
          strong(class: 'partners-paginator__page partners-paginator__page--current') { label }
        else
          link_to(
            label,
            partners_path(**@filter_params, page: range[:page]),
            class: 'partners-paginator__page',
            data: { turbo_frame: 'partner_previews' }
          )
        end
      end
    end
  end

  def page_label(range)
    if range[:first_label] == range[:last_label]
      range[:first_label]
    else
      "#{range[:first_label]} – #{range[:last_label]}"
    end
  end
end
