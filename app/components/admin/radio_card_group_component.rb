# frozen_string_literal: true

module Admin
  class RadioCardGroupComponent < ViewComponent::Base
    # @param form [SimpleForm::FormBuilder] The form builder
    # @param attribute [Symbol] The attribute name (e.g., :role)
    # @param values [Array<String>] Array of values (e.g., ["root", "editor", "citizen"])
    # @param i18n_scope [String] Optional i18n scope for descriptions (e.g., "admin.users.roles")
    def initialize(form:, attribute:, values:, i18n_scope: nil)
      super()
      @form = form
      @attribute = attribute
      @values = values
      @i18n_scope = i18n_scope
    end

    private

    attr_reader :form, :attribute, :values, :i18n_scope

    def model_class
      form.object.class
    end

    def label_for(value)
      name = model_class.human_attribute_name("#{attribute}.#{value}")
      description = i18n_scope ? I18n.t("#{i18n_scope}.#{value}", default: nil) : nil

      if description
        helpers.safe_join([helpers.tag.strong(name), ': ', description])
      else
        name
      end
    end
  end
end
