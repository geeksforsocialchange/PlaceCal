# frozen_string_literal: true

class Components::Hero < Components::Base
  prop :title, String, :positional
  prop :subtitle, _Nilable(String), :positional, default: ''
  prop :schema, _Nilable(String), :positional, default: nil
  # Optional lead paragraph under the title; themes fill it via locale keys.
  prop :standfirst, _Nilable(String), default: nil
  # Optional second, smaller paragraph after the standfirst.
  prop :standfirst_detail, _Nilable(String), default: nil
  # Optional section name shown above the hero (e.g. "Events" on an event page).
  prop :section, _Nilable(String), default: nil

  def after_initialize
    @title = clean_title(@title)
  end

  def view_template
    div(class: 'hero') do
      div(class: 'container-public') do
        p(class: 'hero__section') { @section } if @section.present?
        if @subtitle
          h4(class: 'allcaps') { @subtitle }
          div(role: 'presentation', class: 'hero__divider')
        end
        if @schema
          h1(property: @schema) { safe(@title) }
        else
          h1 { safe(@title) }
        end
        p(class: 'hero__standfirst') { @standfirst } if @standfirst.present?
        p(class: 'hero__standfirst-detail') { @standfirst_detail } if @standfirst_detail.present?
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
