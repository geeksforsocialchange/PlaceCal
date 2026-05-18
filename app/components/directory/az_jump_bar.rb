# frozen_string_literal: true

class Components::Directory::AzJumpBar < Components::Directory::Base
  LETTERS = ('A'..'Z').to_a.freeze

  prop :active_letters, _Interface(:include?), default: -> { Set.new }

  def view_template
    nav(class: 'flex gap-0.5 flex-wrap py-3', aria_label: 'Jump to letter') do
      LETTERS.each do |letter|
        if @active_letters.include?(letter)
          a(href: "#letter-#{letter}", class: "#{letter_base} #{letter_active}") { plain letter }
        else
          a(href: "#letter-#{letter}", class: "#{letter_base} #{letter_inactive}") { plain letter }
        end
      end
    end
  end

  private

  def letter_base
    'w-7 h-7 flex items-center justify-center rounded-sm text-xs font-bold no-underline transition-colors'
  end

  def letter_active
    'bg-home-background-3 text-foreground border border-rules hover:bg-primary'
  end

  def letter_inactive
    'text-tertiary hover:bg-home-background-3'
  end
end
