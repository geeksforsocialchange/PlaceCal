# frozen_string_literal: true

class Components::Admin::SectionHeader < Components::Admin::Base
  prop :title, String
  prop :description, _Nilable(String), default: nil
  prop :tag, Symbol, default: :h2
  prop :margin, Integer, default: 6

  def after_initialize
    @icon_block = nil
  end

  def view_template
    has_icon = @icon_block.present?
    base = 'text-lg font-bold mb-1'
    header_classes = has_icon ? "#{base} flex items-center gap-2" : base

    send(@tag, class: header_classes) do
      @icon_block&.call
      plain @title
    end
    return if @description.blank?

    p(class: "text-sm text-base-content/60 mb-#{@margin}") { @description }
  end
end
