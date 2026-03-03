# frozen_string_literal: true

class Views::Pages::OurStory < Views::Base
  include Views::Pages::Audiences

  def view_template
    article(class: 'home margin') do
      render_introduction
      render_problems
      render_solutions
      render_join
    end
  end

  private

  def render_introduction
    div(class: 'card card--first center') do
      h1(class: 'section') { 'Our story' }
      p(class: 'alt-title-small') { 'We wanted to examine the causes of social isolation and loneliness within neighbourhoods in order to figure out how to combat them. ' }
    end

    div(class: 'card card--plain pattern pattern--research') do
      render(Components::Details.new(
               header: nil,
               summary: '<p>We spoke to over 6,000 people in Manchester and divested over £200,000 in funds directly to community groups.</p><p>A key finding was that people who were isolated commonly thought <em>"There\'s nothing to do in my neighbourhood!"</em>. In communities up and down the country, this has led to social isolation and loneliness for a number of citizens, and therefore a lack of community resilience.</p>'.html_safe
             )) do
        p { 'This is a big issue in the UK in particular, where it is estimated that 2 million older people will be lonely and isolated by 2024. Studies show that social isolation and loneliness is as bad for your health as smoking two packets of cigarettes a week.' }
        p { 'Despite massive investments of time and money by big institutions such as city councils and health providers into event listings, asset maps and community directories, still no one could find out what was happening in their area.' }
        p { 'We continued to work with age friendly partnerships in Hulme and Moss Side (our pilot area, where we are based) to find out why.' }
      end
    end
  end

  def render_problems
    h2(class: 'fc-primary center') { 'We found three big problems' }

    div(class: 'card card--plain') do
      render(Components::Details.new(header: 'People were not working together', summary: 'Every large institution was working on their own community information websites, with different organisations gathering the same data.', image_url: 'home/our_story/not_together.png', image_layout: 'right')) do
        p { 'This top-down approach of people in large institutions trying to gather information on small community groups was inefficient and missed out large swathes of activities and groups.' }
        p { 'It also resulted in duplication, or several low quality results rather than one really good one.' }
      end
    end

    div(class: 'card card--plain') do
      render(Components::Details.new(header: "Current software wasn't working", summary: 'Existing community information websites were either maintained on behalf of the groups by institutional staff or required community groups to regularly log in to keep their events updated.', image_url: 'home/our_story/current_software.png', image_layout: 'left')) do
        p { 'This meant that community groups had to input their information in one site for each provider, in addition to social media sites like Facebook, Twitter and Instagram, creating an ever-increasing amount of work for a very small amount of publicity.' }
      end
    end

    div(class: 'card card--plain') do
      render(Components::Details.new(header: 'Tech skills are very low', summary: 'Digital exclusion has affected community groups disproportionately, particularly in deprived areas such as Manchester. Groups often don\'t have the skills or tools needed to promote themselves effectively.', image_url: 'home/our_story/no_tech_skills.png', image_layout: 'right')) do
        p { 'Staff at many institutions have felt equally left behind by recent innovations.' }
        p { 'Most groups in our neighbourhood had never published anything online about their group at all, relying completely on word of mouth and thereby missing out on many opportunities to connect with new and enthusiastic participants.' }
      end
    end
  end

  def render_solutions
    div(class: 'card card--alt pattern pattern--fixall center our_story__fixall') do
      h2 { 'We needed to fix all of these together to have an impact.' }
      p { 'This meant creating a package of software and training with shared ownership so that everyone could work together to build stronger communities:' }
      br
      image_tag 'home/our_story/logo_onpink.svg'
      br
      br
    end

    div(class: 'card card--plain') do
      render(Components::Details.new(header: 'Collective, not-for-profit ownership', summary: 'To be sustainable, everything must be owned and managed directly by institutions and community groups working together.', image_url: 'home/our_story/collective_ownership.png', image_layout: 'right')) do
        p { 'This supports the existing efforts being done in neighbourhoods by partnerships of councils, community organisers, and public health services.' }
      end
    end

    div(class: 'card card--plain') do
      render(Components::Details.new(header: 'Software built on existing tools', summary: 'Our software builds on top of tools that community groups are already using, such as Google Calendar, Outlook 365, and Facebook.', image_url: 'home/our_story/use_existing_tools.png', image_layout: 'left')) do
        p { 'These listings are then converted into super simple, highly accessible and constantly updated listings for each neighbourhood, community group and venue.' }
      end
    end

    div(class: 'card card--plain') do
      render(Components::Details.new(header: 'A training program that includes everyone', summary: 'Our educational program for institutions and community groups alike walks everyone through the process of publishing and updating their information.', image_url: 'home/our_story/training.png', image_layout: 'right')) do
        p { 'Our educational program for institutions and community groups alike walks everyone through the process of publishing and updating their information.' }
      end
    end
  end

  def render_join
    div(class: 'card card--alt center card--learn-how') do
      h2(class: 'fc-text') { 'Set up PlaceCal in your community' }
      link_to 'Get in touch', get_in_touch_path, class: 'btn btn--big btn--home-2'
    end
  end
end
