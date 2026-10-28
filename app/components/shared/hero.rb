# frozen_string_literal: true

class Components::Shared::Hero < Components::Base
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
  # Optional [label, path] back link, rendered above everything else in the
  # hero (before the section name, when both are present) - "All events" on
  # an event page, say. A generic slot: any page with a hero and an index to
  # return to can use it.
  prop :back, _Nilable(Array), default: nil

  def after_initialize
    @title_lines = title_lines(@title)
  end

  def view_template
    div(class: 'hero hero-pattern bg-primary text-center pt-8 pb-4') do
      div(class: 'container-public') do
        render_back if @back
        p(class: 'hero__section') { @section } if @section.present?
        if @subtitle.present?
          # A paragraph, not a heading, so the outline never skips a level before the h1.
          p(class: 'allcaps inline-block mt-2 mb-6 leading-tight max-md:max-w-56') { @subtitle }
          div(role: 'presentation', class: 'hero__divider mx-auto w-18 border-b-4 border-background')
        end
        if @schema
          h1(property: @schema, class: 'mt-5') { render_title }
        else
          h1(class: 'mt-5') { render_title }
        end
        p(class: 'hero__standfirst') { @standfirst } if @standfirst.present?
        p(class: 'hero__standfirst-detail') { @standfirst_detail } if @standfirst_detail.present?
      end
    end
  end

  private

  def render_back
    label, path = @back
    link_to(label, path, class: 'hero__back block w-fit mx-auto mb-2 text-sm')
  end

  # The title is user or feed supplied (partner names, event summaries, article
  # titles), so it is rendered as text and the long-title line break is a real
  # element rather than markup spliced into the string.
  def render_title
    @title_lines.each_with_index do |line, index|
      if index.positive?
        br(class: 'hidden md:block')
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
