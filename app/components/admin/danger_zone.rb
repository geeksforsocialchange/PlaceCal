# frozen_string_literal: true

class Components::Admin::DangerZone < Components::Admin::Base
  prop :title, String
  prop :description, String
  prop :button_text, String
  prop :button_path, _Any
  prop :button_method, Symbol, default: :delete
  prop :confirm, _Nilable(String), default: nil

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
