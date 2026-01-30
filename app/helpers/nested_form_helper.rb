# frozen_string_literal: true

# Helper methods for nested form functionality (Stimulus-based replacement for Cocoon)
module NestedFormHelper
  # Renders the wrapper for a nested form with add functionality
  #
  # @param form [SimpleForm::FormBuilder] The parent form builder
  # @param association [Symbol] The association name (e.g., :service_areas)
  # @param options [Hash] Options for customization
  # @option options [String] :add_text The text for the add button
  # @option options [String] :add_class CSS classes for the add button
  # @option options [String] :container_class CSS classes for the container
  # @yield Block containing the existing fields iteration
  #
  # Example:
  #   <%= nested_form_for(f, :service_areas, add_text: 'Add Service Area') do %>
  #     <%= f.simple_fields_for :service_areas do |sa| %>
  #       <%= render 'service_area_fields', f: sa %>
  #     <% end %>
  #   <% end %>
  #
  def nested_form_for(form, association, options = {}, &)
    add_text = options.delete(:add_text) || "Add #{association.to_s.singularize.humanize}"
    add_class = options.delete(:add_class) || 'inline-flex items-center px-3 py-2 text-sm font-medium rounded-md text-white bg-placecal-orange hover:bg-orange-600 transition-colors'
    container_class = options.delete(:container_class) || 'space-y-3'

    # Get the partial name from association
    partial = options.delete(:partial) || "#{association.to_s.singularize}_fields"

    # Build a new object for the template
    new_object = form.object.send(association).build
    form_options = { child_index: 'NEW_RECORD' }

    # Render the template content
    template_content = form.simple_fields_for(association, new_object, form_options) do |builder|
      render(partial, f: builder)
    end

    # Remove the built object so it doesn't persist
    form.object.send(association).delete(new_object)

    # Add association-specific class for test selectors (e.g., "sites_neighbourhoods" for service_areas)
    wrapper_class = "nested-form-#{association.to_s.tr('_', '-')}"
    content_tag(:div, class: wrapper_class, data: { controller: 'nested-form' }) do
      safe_join([
                  content_tag(:template, template_content, data: { nested_form_target: 'template' }),
                  content_tag(:div, capture(&), class: container_class, data: { nested_form_target: 'container' }),
                  content_tag(:div, class: 'mt-4') do
                    link_to(add_text, '#', class: add_class, data: { action: 'nested-form#add' })
                  end
                ])
    end
  end

  # Renders a remove link for a nested form item
  #
  # @param form [SimpleForm::FormBuilder] The nested form builder
  # @param text [String] The link text
  # @param options [Hash] HTML options for the link
  #
  def nested_form_remove_link(form, text = 'Remove', options = {})
    options[:class] ||= 'text-sm text-red-600 hover:text-red-800'
    options[:data] ||= {}
    options[:data][:action] = 'nested-form#remove'

    # Add hidden destroy field for existing records
    hidden_field = form.hidden_field(:_destroy, value: false)

    safe_join([hidden_field, link_to(text, '#', options)])
  end
end
