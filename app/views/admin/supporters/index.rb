# frozen_string_literal: true

class Views::Admin::Supporters::Index < Views::Admin::Base
  prop :supporters, ActiveRecord::Relation, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    content_for(:title) { 'Supporters' }

    div(class: 'mb-6') do
      h1(class: 'text-2xl font-semibold text-gray-900') { 'Supporters' }
    end

    div(class: 'mb-4') do
      if view_context.policy(Supporter).create?
        link_to(new_admin_supporter_path, data: { turbo: false },
                                          class: 'inline-flex items-center gap-2 px-4 py-2 text-sm font-medium ' \
                                                 'rounded-lg text-white bg-orange-700 hover:bg-orange-800 ' \
                                                 'transition-colors shadow-sm') do
          icon(:plus, size: '4')
          plain 'Add Supporter'
        end
      end
    end

    render_table
  end

  private

  def render_table # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'bg-white shadow-sm rounded-lg overflow-hidden') do
      table(class: 'min-w-full divide-y divide-gray-200') do
        thead(class: 'bg-gray-50') do
          tr do
            %w[ID Name Logo Global? Actions].each do |heading|
              th(class: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider') { heading }
            end
          end
        end
        tbody(class: 'bg-white divide-y divide-gray-200') do
          supporters.each { |supporter| render_row(supporter) }
        end
      end
    end
  end

  def render_row(supporter) # rubocop:disable Metrics/AbcSize
    tr(class: 'hover:bg-gray-50') do
      td(class: 'px-6 py-4 whitespace-nowrap text-sm text-gray-500') { supporter.id.to_s }
      td(class: 'px-6 py-4 whitespace-nowrap text-sm text-gray-900') { supporter.name }
      td(class: 'px-6 py-4 whitespace-nowrap') do
        image_tag(supporter.logo.url, class: 'h-8 bg-gray-700 rounded') if supporter.logo.url
      end
      td(class: 'px-6 py-4 whitespace-nowrap text-sm text-gray-500') { supporter.is_global ? 'Yes' : 'No' }
      td(class: 'px-6 py-4 whitespace-nowrap text-sm') do
        link_to 'Edit', edit_admin_supporter_path(supporter), data: { turbo: false },
                                                              class: 'text-placecal-orange-dark hover:underline'
      end
    end
  end
end
