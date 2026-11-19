# frozen_string_literal: true

class Views::Admin::Events::Lookup < Views::Admin::Base
  prop :query, String, reader: :private, default: ''
  prop :not_found, _Boolean, reader: :private, default: false

  def view_template
    content_for(:title) { t('admin.events.lookup.title') }

    div(class: 'bg-white shadow-sm rounded-xl overflow-hidden border border-gray-200') do
      div(class: 'px-6 py-5 border-b border-gray-200 bg-gradient-to-r from-gray-50 to-white') do
        h1(class: 'text-xl font-semibold text-gray-900') { t('admin.events.lookup.title') }
        p(class: 'mt-1 text-sm text-gray-600') { t('admin.events.lookup.intro') }
      end
      div(class: 'px-6 py-5') do
        render_form
        p(class: 'mt-3 text-sm text-red-700', role: 'alert') { t('admin.events.lookup.not_found') } if not_found
      end
    end
  end

  private

  def render_form
    form(action: lookup_admin_events_path, method: 'get', role: 'search', class: 'flex flex-wrap items-center gap-2 max-w-2xl') do
      label(for: 'event-lookup', class: 'sr-only') { t('admin.events.lookup.title') }
      input(type: 'search', id: 'event-lookup', name: 'q', value: query, required: true, autofocus: true,
            placeholder: t('admin.events.lookup.placeholder'), class: 'input input-bordered flex-1 min-w-64')
      button(type: 'submit', class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange') { t('admin.events.lookup.submit') }
    end
  end
end
