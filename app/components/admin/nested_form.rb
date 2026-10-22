# frozen_string_literal: true

# Rows for a has_many nested-attributes association, plus a <template> row the nested-form controller clones on add.
class Components::Admin::NestedForm < Components::Admin::Base
  ADD_CLASS = 'btn btn-sm bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange'

  prop :form, ActionView::Helpers::FormBuilder
  prop :association, Symbol
  prop :add_text, String
  prop :add_class, String, default: ADD_CLASS

  def view_template(&row)
    div(class: "nested-form-#{@association.to_s.dasherize}", data_controller: 'nested-form') do
      template(data_nested_form_target: 'template') { rows(new_record, child_index: 'NEW_RECORD', &row) }
      div(class: 'space-y-3', data_nested_form_target: 'container') { rows(&row) }
      div(class: 'mt-4') do
        a(href: '#', class: @add_class, data_action: 'nested-form#add') { @add_text }
      end
    end
  end

  private

  def rows(*, **, &row)
    raw @form.simple_fields_for(@association, *, **, &row)
  end

  def new_record
    @form.object.class.reflect_on_association(@association).klass.new
  end
end
