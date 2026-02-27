# frozen_string_literal: true

class Views::Admin::Components::SectionHeader < Views::Admin::Components::Base
  def initialize(title:, description: nil, tag: :h2, margin: 6, &icon_block)
    @title = title
    @description = description
    @tag = tag
    @margin = margin
    @icon_block = icon_block
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
