# frozen_string_literal: true

class Components::Hero < Components::Base
  prop :title, String, :positional
  prop :subtitle, _Nilable(String), :positional, default: ''
  prop :schema, _Nilable(String), :positional, default: nil

  def after_initialize
    @title = clean_title(@title)
  end

  def view_template
    div(class: 'hero') do
      div(class: 'c') do
        if @subtitle
          h4(class: 'allcaps') { @subtitle }
          div(role: 'presentation', class: 'hero__divider')
        end
        if @schema
          h1(property: @schema) { safe(@title) }
        else
          h1 { safe(@title) }
        end
      end
    end
  end

  private

  def clean_title(title)
    if title.length > 32
      title.split.in_groups(2, false).map { |g| g.join(' ') }.join('<br> ')
    else
      title
    end
  end
end
