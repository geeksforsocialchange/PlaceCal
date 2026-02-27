# frozen_string_literal: true

class Components::Admin::NeighbourhoodCard < Components::Admin::Base
  include NeighbourhoodsHelper

  prop :neighbourhood, ::Neighbourhood
  prop :show_header, _Boolean, default: true
  prop :show_remove, _Boolean, default: false
  prop :form, _Nilable(_Any), default: nil
  prop :inline, _Boolean, default: false

  def view_template
    div(class: 'nested-fields card bg-base-200/50 border border-base-300') do
      div(class: 'card-body p-4 gap-3') do
        if @show_header
          h3(class: 'font-semibold flex items-center gap-2') do
            icon(:neighbourhood, size: '4')
            plain t('admin.address.neighbourhood_label')
          end
        end

        div(class: 'flex items-center justify-between gap-2') do
          div(class: 'flex-1') do
            render_current_neighbourhood
            render_ancestors
          end

          if @show_remove && @form
            nested_form_remove_link(@form, capture { icon(:x, size: '4') },
                                    class: 'btn btn-ghost btn-sm btn-square text-gray-500 hover:text-error hover:bg-error/10')
          end
        end
      end
    end
  end

  private

  def render_current_neighbourhood
    link_to admin_neighbourhood_path(@neighbourhood),
            class: 'flex items-center gap-2 py-2 pr-2 rounded-lg hover:bg-base-300/50 transition-colors group' do
      level_badge(@neighbourhood.level)
      div do
        span(class: 'text-base font-semibold text-base-content group-hover:text-placecal-orange transition-colors') do
          @neighbourhood.shortname
        end
        span(class: 'text-xs text-gray-600 ml-1') { @neighbourhood.unit&.titleize }
      end
    end
  end

  def render_ancestors
    ancestors = @neighbourhood.ancestors.order(:ancestry)
    return unless ancestors.any?

    div(class: 'flex flex-wrap items-center gap-1') do
      ancestors.each_with_index do |ancestor, index|
        span(class: 'text-gray-300') { '/' } if index.positive?
        link_to admin_neighbourhood_path(ancestor),
                class: "inline-flex items-center gap-1 px-1.5 py-0.5 text-xs rounded #{neighbourhood_colour(ancestor.level)} hover:opacity-80 transition-opacity" do
          plain ancestor.shortname
        end
      end
    end
  end
end
