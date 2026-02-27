# frozen_string_literal: true

class Components::Admin::Fieldset < Components::Admin::Base
  prop :label, String
  prop :hint, _Nilable(String), default: nil
  prop :required, _Boolean, default: false
  prop :char_counter, _Nilable(_Any), default: nil

  def after_initialize
    @input_block = nil
  end

  def with_input(&block)
    @input_block = block
    self
  end

  def view_template(&content_block)
    attrs = { class: 'fieldset' }
    if @char_counter.present?
      attrs[:data_controller] = 'char-counter'
      attrs[:data_char_counter_max_value] = @char_counter
    end

    fieldset(**attrs) do
      legend(class: 'fieldset-legend') do
        plain @label
        if @required
          whitespace
          span(class: 'text-error') { '*' }
        end
        if @char_counter.present?
          whitespace
          span(class: 'text-gray-600 font-normal ml-2', data_char_counter_target: 'display') { "0/#{@char_counter}" }
        end
      end
      if @input_block
        @input_block.call
      elsif content_block
        yield
      end
      p(class: 'fieldset-label') { @hint } if @hint.present?
    end
  end
end
