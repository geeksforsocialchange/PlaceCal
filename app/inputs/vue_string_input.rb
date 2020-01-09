# app/inputs/vue_string_input.rb

class VueStringInput < SimpleForm::Inputs::StringInput
  def merge_wrapper_options(options, wrapper_options)
    if wrapper_options
      wrapper_options = set_input_classes(wrapper_options)

      wrapper_options.merge(options) do |key, oldval, newval|
        case key.to_s
        when "class"
          Array(oldval) + Array(newval)
        when "data", "aria", "v"
          oldval.merge(newval)
        else
          newval
        end
      end
    else
      options
    end
  end
end
