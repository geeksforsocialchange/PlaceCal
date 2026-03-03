# frozen_string_literal: true

class Views::Admin::Collections::Index < Views::Admin::Base
  prop :collections, _Any, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    content_for(:title) { 'Collections' }

    div(class: 'mb-6') do
      h1(class: 'text-2xl font-semibold text-gray-900') { 'Collections' }
    end

    div(class: 'mb-4') do
      if view_context.policy(Collection).create?
        link_to(new_admin_collection_path, data: { turbo: false },
                                           class: 'inline-flex items-center gap-2 px-4 py-2 text-sm font-medium ' \
                                                  'rounded-lg text-white bg-orange-700 hover:bg-orange-800 ' \
                                                  'transition-colors shadow-sm') do
          icon(:plus, size: '4')
          plain 'Add Collection'
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
            %w[ID Name Description Actions].each do |heading|
              th(class: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider') { heading }
            end
          end
        end
        tbody(class: 'bg-white divide-y divide-gray-200') do
          collections.each { |collection| render_row(collection) }
        end
      end
    end
  end

  def render_row(collection) # rubocop:disable Metrics/AbcSize
    tr(class: 'hover:bg-gray-50') do
      td(class: 'px-6 py-4 whitespace-nowrap text-sm text-gray-500') { collection.id.to_s }
      td(class: 'px-6 py-4 whitespace-nowrap text-sm text-gray-900') { collection.name }
      td(class: 'px-6 py-4 text-sm text-gray-500') { view_context.truncate(collection.description, length: 100) }
      td(class: 'px-6 py-4 whitespace-nowrap text-sm') do
        link_to 'Edit', edit_admin_collection_path(collection), data: { turbo: false },
                                                                class: 'text-placecal-orange-dark hover:underline'
      end
    end
  end
end
