# frozen_string_literal: true

class Views::Admin::Collections::Form < Views::Admin::Base
  prop :collection, Collection, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    simple_form_for([:admin, collection], html: { class: 'space-y-6' }) do |form|
      Error(collection)

      div(class: 'bg-white shadow-sm rounded-lg p-6 space-y-4') do
        h3(class: 'text-lg font-medium text-gray-900 border-b border-gray-200 pb-2') { 'Collection Details' }
        raw form.input(:name, id: :collection_name, wrapper: :tw_vertical_form,
                              input_html: { class: 'block w-full rounded-md border-gray-300 shadow-sm focus:border-placecal-orange focus:ring-placecal-orange sm:text-sm' })
        raw form.input(:route, wrapper: :tw_vertical_form,
                               input_html: { class: 'block w-full rounded-md border-gray-300 shadow-sm focus:border-placecal-orange focus:ring-placecal-orange sm:text-sm' })
        raw form.input(:description, wrapper: :tw_vertical_form,
                                     input_html: { class: 'block w-full rounded-md border-gray-300 shadow-sm focus:border-placecal-orange focus:ring-placecal-orange sm:text-sm', rows: 3 })
      end

      div(class: 'bg-white shadow-sm rounded-lg p-6 space-y-4') do
        h3(class: 'text-lg font-medium text-gray-900 border-b border-gray-200 pb-2') { 'Events' }
        raw form.association(:events, collection: options_for_events,
                                      wrapper: :tw_vertical_form,
                                      input_html: { class: 'block w-full', data: { controller: 'tom-select' } })
      end

      div(class: 'bg-white shadow-sm rounded-lg p-6 space-y-4') do
        h3(class: 'text-lg font-medium text-gray-900 border-b border-gray-200 pb-2') { 'Image' }
        raw form.input(:image, wrapper: :tw_file)
        if form.object.image.size.positive?
          div(class: 'mt-4') do
            image_tag(form.object.image.url, class: 'rounded-lg max-w-xs') if form.object.image.url
            p(class: 'text-sm text-gray-500 mt-2') { 'Current image' }
          end
        end
      end

      render_submit_buttons(form)
    end
  end

  private

  def render_submit_buttons(form)
    div(class: 'flex items-center gap-4 pt-4') do
      raw form.button(:submit, class: 'inline-flex justify-center rounded-md bg-placecal-orange px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-orange-600 focus:outline-none focus:ring-2 focus:ring-placecal-orange focus:ring-offset-2')
      unless collection.new_record?
        link_to('Destroy Collection', helpers.admin_collection_path(collection), method: :delete,
                                                                                 class: 'inline-flex justify-center rounded-md bg-red-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500',
                                                                                 data: { confirm: 'Are you sure you want to delete this collection?' })
      end
    end
  end
end
