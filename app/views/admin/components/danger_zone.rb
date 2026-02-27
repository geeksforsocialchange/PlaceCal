# frozen_string_literal: true

class Views::Admin::Components::DangerZone < Views::Admin::Components::Base
  def initialize(title:, description:, button_text:, button_path:, button_method: :delete, confirm: nil) # rubocop:disable Metrics/ParameterLists
    @title = title
    @description = description
    @button_text = button_text
    @button_path = button_path
    @button_method = button_method
    @confirm = confirm
  end

  def view_template
    div(class: 'card bg-error/5 border border-error/20') do
      div(class: 'card-body p-4') do
        h3(class: 'font-semibold flex items-center gap-2 text-error') do
          icon(:warning, size: '5')
          plain @title
        end
        p(class: 'text-sm text-base-content/70 mt-2') { @description }
        div(class: 'mt-4') do
          turbo_data = { turbo_method: @button_method }
          turbo_data[:turbo_confirm] = @confirm if @confirm
          link_to @button_path, data: turbo_data, class: 'btn btn-error btn-sm' do
            icon(:trash, size: '4')
            plain " #{@button_text}"
          end
        end
      end
    end
  end
end
