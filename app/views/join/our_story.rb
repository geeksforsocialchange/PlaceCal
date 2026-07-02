# frozen_string_literal: true

# Condensed origin story for the join site. The apex directory keeps its own
# longer version (Views::Directory::OurStory).
class Views::Join::OurStory < Views::Join::Base
  def view_template
    content_for(:title) { t('join.our_story.title') }

    section(class: 'py-10') do
      div(class: 'container-editorial') do
        breadcrumb([t('join.nav.our_story')])
        h1(class: 'join-headline m-0 mb-2') { t('join.our_story.title') }
        p(class: 'text-card text-tertiary leading-normal mt-0 mb-8') { t('join.our_story.lede') }
        p(class: 'mt-0 mb-4') { t('join.our_story.research_1') }
        p(class: 'mt-0 mb-8') { t('join.our_story.research_2') }
        render_problems
        render_fix
      end
    end
  end

  private

  def render_problems
    h2(class: 'font-serif font-regular text-section text-foreground mt-8 mb-4') { t('join.our_story.problems_heading') }
    t('join.our_story.problems').each do |problem|
      div(class: 'py-4 border-b border-rules') do
        h3(class: 'font-serif font-regular text-card text-foreground m-0 mb-1') { problem[:title] }
        p(class: 'text-tertiary m-0') { problem[:body] }
      end
    end
  end

  def render_fix
    div(class: 'bg-secondary rounded-card p-8 text-center mt-8') do
      h2(class: 'font-serif font-regular text-section text-foreground m-0') { t('join.our_story.fix_heading') }
      p(class: 'mt-2 mb-0') { t('join.our_story.fix_body') }
    end
  end
end
