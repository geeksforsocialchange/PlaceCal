# frozen_string_literal: true

module Admin
  class TabPanelComponent < ViewComponent::Base
    def initialize(name:, label:, hash:, controller_name:, checked: false)
      super()
      @name = name
      @label = label
      @hash = hash
      @controller_name = controller_name
      @checked = checked
    end

    private

    attr_reader :name, :label, :hash, :controller_name, :checked
  end
end
