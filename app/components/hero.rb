# frozen_string_literal: true

class Components::Hero < Components::Base
  prop :title, String, :positional
  prop :subtitle, _Nilable(String), :positional, default: ''
  # RDFa property name for the h1, when the page wraps the hero in a vocab.
  prop :schema, _Nilable(String), default: nil
  # Optional lead paragraph under the title; themes fill it via locale keys.
  prop :standfirst, _Nilable(String), default: nil
  # Optional second, smaller paragraph after the standfirst.
  prop :standfirst_detail, _Nilable(String), default: nil
  # Optional section name shown above the hero (e.g. "Events" on an event page).
  prop :section, _Nilable(String), default: nil

  def after_initialize
    @title_lines = title_lines(@title)
  end

  def view_template
    div(class: 'hero') do
      div(class: 'container-public') do
        p(class: 'hero__section') { @section } if @section.present?
        if @subtitle
          # The tagline is a strapline, not a section title. It used to be an h4
          # sitting between the navigation's h2 site name and the page h1, which
          # skipped a heading level and failed axe's heading-order rule.
          p(class: 'allcaps') { @subtitle }
          div(role: 'presentation', class: 'hero__divider')
        end
        if @schema
          h1(property: @schema) { render_title }
        else
          h1 { render_title }
        end
        p(class: 'hero__standfirst') { @standfirst } if @standfirst.present?
        p(class: 'hero__standfirst-detail') { @standfirst_detail } if @standfirst_detail.present?
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
