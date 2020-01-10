# app/inputs/vue_string_input.rb

module SimpleForm
  module Components
    module VueModel
      def vue_model(wrapper_options = nil)
        input_html_options[:'v-model'] ||= options[:'v-model']
        nil
      end
    end
  end
end

class VueStringInput < SimpleForm::Inputs::StringInput
  enable :placeholder, :maxlength, :minlength, :pattern, :vue_model

  def input(wrapper_options = nil)
    unless string?
      input_html_classes.unshift("string")
      input_html_options[:type] ||= input_type if html5?
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    puts merged_input_options
    # merged_input_options[:'v-model'] = attribute_name
    @builder.text_field(attribute_name, merged_input_options)
  end
end
