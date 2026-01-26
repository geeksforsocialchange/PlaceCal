# frozen_string_literal: true

# Simple Form Tailwind configuration
# Used alongside Bootstrap config during migration period

SimpleForm.setup do |config|
  # Tailwind wrappers - using tw_ prefix to avoid conflicts with Bootstrap wrappers

  # Default vertical form wrapper
  config.wrappers :tw_vertical_form, tag: 'div', class: 'mb-4', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'block text-sm font-medium text-gray-700 mb-1'
    b.use :input, class: 'block w-full rounded-md border-gray-300 shadow-sm focus:border-placecal-orange focus:ring-placecal-orange sm:text-sm',
                  error_class: 'border-red-500'
    b.use :full_error, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-red-600' }
    b.use :hint, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-gray-500' }
  end

  # Tailwind boolean wrapper (checkbox)
  config.wrappers :tw_boolean, tag: 'div', class: 'mb-4', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper tag: 'div', class: 'flex items-center' do |ba|
      ba.use :input, class: 'h-4 w-4 rounded border-gray-300 text-placecal-orange focus:ring-placecal-orange'
      ba.use :label, class: 'ml-2 block text-sm text-gray-700'
    end
    b.use :full_error, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-red-600' }
    b.use :hint, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-gray-500' }
  end

  # Tailwind select wrapper
  config.wrappers :tw_select, tag: 'div', class: 'mb-4', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'block text-sm font-medium text-gray-700 mb-1'
    b.use :input, class: 'block w-full rounded-md border-gray-300 shadow-sm focus:border-placecal-orange focus:ring-placecal-orange sm:text-sm',
                  error_class: 'border-red-500'
    b.use :full_error, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-red-600' }
    b.use :hint, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-gray-500' }
  end

  # Tailwind textarea wrapper
  config.wrappers :tw_text, tag: 'div', class: 'mb-4', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :readonly
    b.use :label, class: 'block text-sm font-medium text-gray-700 mb-1'
    b.use :input, class: 'block w-full rounded-md border-gray-300 shadow-sm focus:border-placecal-orange focus:ring-placecal-orange sm:text-sm',
                  error_class: 'border-red-500'
    b.use :full_error, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-red-600' }
    b.use :hint, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-gray-500' }
  end

  # Tailwind file input wrapper
  config.wrappers :tw_file, tag: 'div', class: 'mb-4', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'block text-sm font-medium text-gray-700 mb-1'
    b.use :input, class: 'block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-md file:border-0 file:text-sm file:font-semibold file:bg-placecal-orange file:text-white hover:file:bg-orange-600',
                  error_class: 'border-red-500'
    b.use :full_error, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-red-600' }
    b.use :hint, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-gray-500' }
  end

  # Tailwind collection (radio/checkboxes)
  config.wrappers :tw_collection, item_wrapper_class: 'flex items-center mb-2', tag: 'fieldset', class: 'mb-4',
                                  error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper :legend_tag, tag: 'legend', class: 'block text-sm font-medium text-gray-700 mb-2' do |ba|
      ba.use :label_text
    end
    b.use :input, class: 'h-4 w-4 border-gray-300 text-placecal-orange focus:ring-placecal-orange',
                  error_class: 'border-red-500'
    b.use :full_error, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-red-600' }
    b.use :hint, wrap_with: { tag: 'p', class: 'mt-1 text-sm text-gray-500' }
  end
end
