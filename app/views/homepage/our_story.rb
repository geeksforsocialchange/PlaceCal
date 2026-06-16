# frozen_string_literal: true

class Views::Homepage::OurStory < Views::Homepage::Base
  IMAGE_BASE = 'home/our_story'

  # Problem and solution cards share an identical structure, so they're driven
  # from data and rendered by +render_card+. Copy lives in the locale file under
  # directory.pages.our_story.{problems,solutions}.<key>.
  PROBLEMS = [
    { key: :not_working_together, image: 'not_together.png', layout: 'right' },
    { key: :software_not_working, image: 'current_software.png', layout: 'left' },
    { key: :low_tech_skills, image: 'no_tech_skills.png', layout: 'right' }
  ].freeze

  SOLUTIONS = [
    { key: :collective_ownership, image: 'collective_ownership.png', layout: 'right' },
    { key: :existing_tools, image: 'use_existing_tools.png', layout: 'left' },
    { key: :training, image: 'training.png', layout: 'right' }
  ].freeze

  def view_template
    article(class: 'home margin') do
      render_introduction
      render_problems
      render_solutions
      render_join
    end
  end

  private

  def t_story(key, **)
    t("directory.pages.our_story.#{key}", **)
  end

  def render_introduction
    div(class: 'card card--first center') do
      h1(class: 'section') { t_story(:heading) }
      p(class: 'alt-title-small') { t_story(:lede) }
    end

    div(class: 'card card--plain pattern pattern--research') do
      Details(summary_content: research_summary) do
        t_story('research.body').each { |paragraph| p { paragraph } }
      end
    end
  end

  # Rendered in the Details component's context, so only the Phlex DSL and
  # translation helper are available here (no view-level helpers).
  def research_summary
    lambda do
      p { t('directory.pages.our_story.research.stats') }
      p do
        plain t('directory.pages.our_story.research.finding_intro')
        em { t('directory.pages.our_story.research.finding_quote') }
        plain t('directory.pages.our_story.research.finding_outro')
      end
    end
  end

  def render_problems
    h2(class: 'fc-primary center') { t_story(:problems_heading) }
    PROBLEMS.each { |card| render_card(:problems, card) }
  end

  def render_solutions
    div(class: 'card card--alt pattern pattern--fixall center our_story__fixall') do
      h2 { t_story('solutions.heading') }
      p { t_story('solutions.intro') }
      br
      image_tag "#{IMAGE_BASE}/logo_onpink.svg", alt: t_story('solutions.logo_alt')
      br
      br
    end

    SOLUTIONS.each { |card| render_card(:solutions, card) }
  end

  def render_card(section, card)
    base = "#{section}.#{card[:key]}"
    body = t_story("#{base}.body", default: nil)
    attrs = {
      header: t_story("#{base}.header"),
      summary: t_story("#{base}.summary"),
      image_url: "#{IMAGE_BASE}/#{card[:image]}",
      image_layout: card[:layout]
    }

    div(class: 'card card--plain') do
      if body
        Details(**attrs) { body.each { |paragraph| p { paragraph } } }
      else
        Details(**attrs)
      end
    end
  end

  def render_join
    div(class: 'card card--alt center card--learn-how') do
      h2(class: 'fc-text') { t_story('join.heading') }
      link_to t_story('join.cta'), get_in_touch_path, class: 'btn btn--big btn--home-2'
    end
  end
end
