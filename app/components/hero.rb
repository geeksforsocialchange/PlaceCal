# frozen_string_literal: true

class Components::Hero < Components::Base
  prop :title, String, :positional
  prop :subtitle, _Nilable(String), :positional, default: ''
  prop :schema, _Nilable(String), :positional, default: nil

  def after_initialize
    @title_lines = title_lines(@title)
  end

  def view_template
    div(class: 'hero') do
      div(class: 'container-public') do
        if @subtitle
          h4(class: 'allcaps') { @subtitle }
          div(role: 'presentation', class: 'hero__divider')
        end
        if @schema
          h1(property: @schema) { render_title }
        else
          h1 { render_title }
        end
      end
    end
  end

  private

  # The title is user or feed supplied (partner names, event summaries, article
  # titles), so it is rendered as text and the long-title line break is a real
  # element rather than markup spliced into the string.
  def render_title
    @title_lines.each_with_index do |line, index|
      if index.positive?
        br
        plain ' '
      end
      plain line
    end
  end

  def title_lines(title)
    return [title] if title.length <= 32

    title.split.in_groups(2, false).map { |group| group.join(' ') }
  end
end
