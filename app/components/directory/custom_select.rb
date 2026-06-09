# frozen_string_literal: true

class Components::Directory::CustomSelect < Components::Directory::Base
  prop :name, String
  prop :label_text, String
  prop :options, _Interface(:each)
  prop :selected, _Nilable(String), default: nil
  prop :default_label, _Nilable(String), default: nil
  prop :include_blank, _Boolean, default: true

  def view_template
    div(class: 'min-w-0 flex-1 relative', data: { controller: 'custom-select' }) do
      label(class: 'block allcaps-label text-tertiary mb-1') { @label_text }
      render_hidden_select
      render_trigger
      render_panel
    end
  end

  private

  def render_hidden_select
    select(
      name: @name, id: @name,
      data: { custom_select_target: 'hiddenSelect' },
      class: 'sr-only', tabindex: '-1', aria: { hidden: 'true' }
    ) do
      all_options.each do |opt|
        attrs = { value: opt[:value] }
        attrs[:selected] = true if opt[:value].to_s == @selected.to_s
        option(**attrs) { opt[:label] }
      end
    end
  end

  def render_trigger
    button(
      type: 'button',
      data: { custom_select_target: 'trigger', action: 'custom-select#toggle' },
      class: 'w-full flex items-center justify-between border-2 border-rules rounded-sm px-4 py-2 text-sm bg-background text-foreground cursor-pointer hover:border-foreground transition-colors'
    ) do
      span(class: 'truncate min-w-0 text-left', data: { role: 'label' }) { selected_label }
      span(
        data: { custom_select_target: 'arrow' },
        class: 'transition-transform duration-200 shrink-0'
      ) { raw(chevron_svg) }
    end
  end

  def render_panel
    div(
      data: { custom_select_target: 'panel' },
      style: 'display: none',
      class: 'absolute z-50 left-0 right-0 mt-1 bg-foreground rounded-sm overflow-hidden shadow-lg'
    ) do
      div(class: 'max-h-[60vh] overflow-y-auto py-1') do
        all_options.each do |opt|
          render_option(opt)
        end
      end
    end
  end

  def render_option(opt)
    is_selected = opt[:value].to_s == @selected.to_s
    button(
      type: 'button',
      data: {
        custom_select_target: 'option',
        action: 'custom-select#select',
        value: opt[:value],
        label: opt[:label],
        selected: is_selected.to_s
      },
      class: 'custom-select-option w-full text-left px-4 py-2 text-sm cursor-pointer transition-colors'
    ) do
      span(class: 'text-background/50 text-2xs block mb-0.5') { opt[:group] } if opt[:group]
      plain opt[:label]
    end
  end

  def all_options
    @all_options ||= if @include_blank
                       [{ value: '', label: placeholder }] + flat_options
                     else
                       flat_options
                     end
  end

  def flat_options
    @options.flat_map do |item|
      if item.is_a?(Hash) && item[:group]
        item[:items].map { |i| { value: i[:id].to_s, label: display_label(i), group: item[:group] } }
      elsif item.is_a?(Hash)
        [{ value: (item[:id] || item[:value] || item[:slug]).to_s, label: display_label(item) }]
      else
        [{ value: item.to_s, label: item.to_s }]
      end
    end
  end

  def display_label(item)
    if item[:count]
      "#{item[:name]} (#{item[:count]})"
    else
      item[:name] || item[:label] || item.to_s
    end
  end

  def placeholder
    @default_label || "All #{@label_text.downcase.pluralize}"
  end

  def selected_label
    match = all_options.find { |o| o[:value].to_s == @selected.to_s }
    match ? match[:label] : placeholder
  end

  def chevron_svg
    safe('<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9l6 6 6-6"/></svg>')
  end
end
