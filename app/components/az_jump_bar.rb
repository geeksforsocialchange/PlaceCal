# frozen_string_literal: true

# TODO(#3163): Move to app/directory/components/az_jump_bar.rb
class Components::AzJumpBar < Components::Base
  LETTERS = ('A'..'Z').to_a.freeze

  prop :active_letters, _Interface(:include?), default: -> { Set.new }

  def view_template
    nav(class: 'flex gap-0.5 flex-wrap py-3', aria_label: 'Jump to letter') do
      a(href: '#partner-list',
        class: 'w-7 h-7 flex items-center justify-center rounded text-[0.72rem] font-bold bg-foreground text-background no-underline hover:bg-primary transition-colors') do
        plain 'All'
      end
      LETTERS.each do |letter|
        if @active_letters.include?(letter)
          a(href: "#letter-#{letter}",
            class: 'w-7 h-7 flex items-center justify-center rounded text-[0.78rem] font-bold bg-foreground text-background no-underline hover:bg-primary transition-colors') do
            plain letter
          end
        else
          span(class: 'w-7 h-7 flex items-center justify-center rounded text-[0.78rem] text-rules-dark') do
            plain letter
          end
        end
      end
    end
  end
end
