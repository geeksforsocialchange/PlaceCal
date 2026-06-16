# frozen_string_literal: true

class Components::Directory::AzJumpBar < Components::Directory::Base
  LETTERS = ('A'..'Z').to_a.freeze

  prop :active_letters, _Interface(:include?), default: -> { Set.new }
  prop :selected_letter, _Nilable(String), default: nil
  prop :filter_params, Hash, default: -> { {} }

  def view_template
    nav(class: 'flex gap-0.5 flex-wrap py-3', aria_label: t('directory.aria.filter_by_letter')) do
      render_all_link
      LETTERS.each do |letter|
        if @active_letters.include?(letter)
          if letter == @selected_letter
            span(class: "#{letter_base} #{letter_selected}") { plain letter }
          else
            a(href: letter_path(letter), class: "#{letter_base} #{letter_active}") { plain letter }
          end
        else
          span(class: "#{letter_base} #{letter_inactive}") { plain letter }
        end
      end
    end
  end

  private

  def render_all_link
    if @selected_letter.nil?
      span(class: "#{letter_base} #{letter_selected} w-auto px-2") { plain t('directory.filters.all') }
    else
      a(href: all_path, class: "#{letter_base} #{letter_active} w-auto px-2") { plain t('directory.filters.all') }
    end
  end

  def letter_path(letter)
    "#{partners_path}?#{@filter_params.merge('sort' => 'name', 'letter' => letter).to_query}"
  end

  def all_path
    "#{partners_path}?#{@filter_params.merge('sort' => 'name').to_query}"
  end

  def letter_base
    'w-7 h-7 flex items-center justify-center rounded-sm text-xs font-bold no-underline transition-colors'
  end

  def letter_selected
    'bg-foreground text-background'
  end

  def letter_active
    'text-foreground hover:bg-home-background-3'
  end

  def letter_inactive
    'text-rules cursor-default'
  end
end
