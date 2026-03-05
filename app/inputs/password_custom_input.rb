# frozen_string_literal: true

# https://arjanvandergaag.nl/blog/simpleform-custom-inputs.html
# https://blog.appsignal.com/2024/05/15/creating-forms-in-ruby-on-rails-with-simple-form.html
# https://github.com/heartcombo/simple_form?tab=readme-ov-file#custom-inputs
# https://rubydoc.info/github/heartcombo/simple_form/main/SimpleForm/Inputs/PasswordInput

# Password Custom Input
#
# SimpleForm password input with a show/hide toggle button
#
# Uses `app/javascript/controllers/password_toggle_controller.js`
#
# To use: `<%= f.input :password, as: :password_custom %>`
class PasswordCustomInput < SimpleForm::Inputs::PasswordInput
  include SvgIconsHelper

  def input(wrapper_options)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    merged_input_options[:autocomplete] = 'off'
    merged_input_options[:required] = true
    merged_input_options[:data] = { password_toggle_target: 'input' }

    # tag is ActiveView and it only renders the last child of each parent. i think it's meant to be used in erb templates
    # tag.div(class: 'input__group', data: { controller: 'password-toggle' }) do
    #   @builder.text_field(attribute_name, merged_input_options)
    #   tag.button(type: 'button', role: 'checkbox', 'aria-label': 'Show password', data: { 'password-toggle-target': 'button' }) do
    #     svg_icon(:eye, size: nil)
    #     svg_icon(:strike, size: nil, css_class: 'checked')
    #   end
    # end

    # FIXME: i have no idea how to make Phlex work here
    # rubocop:disable Rails/OutputSafety
    "<div class=\"input__group\"  data-controller=\"password-toggle\">
      #{@builder.text_field(attribute_name, merged_input_options)}
      <button type=\"button\" role=\"checkbox\" aria-label=\"Show password\" data-password-toggle-target=\"button\">
        #{svg_icon(:eye, size: nil)}
        #{svg_icon(:strike, size: nil, css_class: 'checked')}
      </button>
    </div>".html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
