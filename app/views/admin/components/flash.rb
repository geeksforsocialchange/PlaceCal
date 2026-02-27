# frozen_string_literal: true

class Views::Admin::Components::Flash < Views::Admin::Components::Base
  def initialize(flash: nil)
    @flash = flash
  end

  def view_template
    flash_messages = @flash || helpers.flash
    return unless flash_messages.any?

    div(class: 'space-y-3 mb-3') do
      flash_messages.each do |key, value|
        render Views::Admin::Components::Alert.new(type: key, message: value)
      end
    end
  end
end
