# frozen_string_literal: true

class Views::Admin::Supporters::Form < Views::Admin::Base
  prop :supporter, Supporter, reader: :private

  def view_template
    simple_form_for([:admin, supporter], html: { class: 'space-y-6' }) do |form|
      Error(supporter) if supporter.errors.any?

      div(class: 'bg-white shadow-sm rounded-lg p-6 space-y-4') do
        h3(class: 'text-lg font-medium text-gray-900 border-b border-gray-200 pb-2') { 'Supporter Details' }
        raw form.input(:name, wrapper: :tw_vertical_form,
                              input_html: { class: 'block w-full rounded-md border-gray-300 shadow-sm focus:border-placecal-orange focus:ring-placecal-orange sm:text-sm' })
        raw form.input(:url, wrapper: :tw_vertical_form,
                             input_html: { class: 'block w-full rounded-md border-gray-300 shadow-sm focus:border-placecal-orange focus:ring-placecal-orange sm:text-sm' })
        raw form.input(:description, wrapper: :tw_vertical_form,
                                     input_html: { class: 'block w-full rounded-md border-gray-300 shadow-sm focus:border-placecal-orange focus:ring-placecal-orange sm:text-sm', rows: 3 })
      end

      div(class: 'bg-white shadow-sm rounded-lg p-6 space-y-4') do
        h3(class: 'text-lg font-medium text-gray-900 border-b border-gray-200 pb-2') { 'Logo' }
        raw form.input(:logo, wrapper: :tw_file)
        if form.object.logo.url
          div(class: 'mt-4') do
            image_tag(form.object.logo.url, class: 'rounded-lg max-w-xs')
            p(class: 'text-sm text-gray-500 mt-2') { 'Current logo' }
          end
        end
      end

      div(class: 'bg-white shadow-sm rounded-lg p-6 space-y-4') do
        h3(class: 'text-lg font-medium text-gray-900 border-b border-gray-200 pb-2') { 'Display Settings' }
        raw form.input(:weight, wrapper: :tw_vertical_form,
                                input_html: { class: 'block w-full rounded-md border-gray-300 shadow-sm focus:border-placecal-orange focus:ring-placecal-orange sm:text-sm' },
                                hint: 'Higher weight = appears first')
        raw form.input(:is_global, wrapper: :tw_boolean, hint: 'Show this supporter on all sites')
      end

      div(class: 'bg-white shadow-sm rounded-lg p-6 space-y-4') do
        h3(class: 'text-lg font-medium text-gray-900 border-b border-gray-200 pb-2') { 'Sites' }
        p(class: 'text-sm text-gray-600') { 'Select which sites this supporter should appear on' }
        raw form.association(:sites, as: :check_boxes, wrapper: :tw_collection)
      end

      render_submit_buttons(form)
    end
  end

  private

  def render_submit_buttons(form)
    div(class: 'flex items-center gap-4 pt-4') do
      raw form.button(:submit, class: 'inline-flex justify-center rounded-md bg-placecal-orange px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-orange-600 focus:outline-none focus:ring-2 focus:ring-placecal-orange focus:ring-offset-2')
      unless supporter.new_record?
        link_to('Destroy Supporter', helpers.admin_supporter_path(supporter), method: :delete,
                                                                              class: 'inline-flex justify-center rounded-md bg-red-600 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500',
                                                                              data: { confirm: 'Are you sure you want to delete this supporter?' })
      end
    end
  end
end
