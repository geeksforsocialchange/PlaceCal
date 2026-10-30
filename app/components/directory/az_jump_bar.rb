# frozen_string_literal: true

class Components::Directory::AzJumpBar < Components::Directory::Base
  LETTERS = ('A'..'Z').to_a.freeze

  prop :active_letters, _Interface(:include?), default: -> { Set.new }
  prop :selected_letter, _Nilable(String), default: nil
  prop :filter_params, Hash, default: -> { {} }

  def view_template
    nav(class: 'flex gap-0.5 flex-wrap py-3', aria_label: t('directory.aria.filter_by_letter')) do
      UI::Pill(variant: :letter, selected: @selected_letter.nil?, href: all_path) { plain t('directory.filters.all') }
      LETTERS.each do |letter|
        active = @active_letters.include?(letter)
        UI::Pill(variant: :letter, selected: letter == @selected_letter, disabled: !active, href: letter_path(letter)) { plain letter }
      end
    end
  end

  private

  def letter_path(letter)
    "#{partners_path}?#{@filter_params.merge('sort' => 'name', 'letter' => letter).to_query}"
  end

  def all_path
    "#{partners_path}?#{@filter_params.merge('sort' => 'name').to_query}"
  end
end
