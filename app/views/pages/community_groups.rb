# frozen_string_literal: true

class Views::Pages::CommunityGroups < Views::Base
  include Views::Pages::Audiences

  def view_template
    article(class: 'home') do
      div(class: 'margin') do
        render_hero
        render_details
        render_steps
        render_impact
        h2(class: 'fc-primary center') { 'How PlaceCal helps other groups' }
        render_audiences(exclude: :community_groups)
      end
    end
  end

  private

  def render_hero
    div(class: 'card card--first center') do
      h1(class: 'section') { 'How we help community groups' }
    end
  end

  def render_details
    div(class: 'card card--plain pattern pattern--audience') do
      render(Components::Details.new(
               header: 'We turn your local knowledge into great community information websites',
               header_class: 'center alt-title',
               header_level: 2,
               summary: '<p>We know first hand that community partnerships are often cash strapped and time poor, but are often delivering the most important and life-changing support to the most vulnerable in society.</p><p class="details__summary__collapsible">The PlaceCal process helps make the most of the little time you have, and works with what community groups are already using, in some cases requiring no additional effort.</p>',
               image_url: 'home/audiences/communities_wide.jpg',
               image_alt: 'A photograph of a middle aged woman and young girl enjoying a pottery class',
               image_layout: 'center'
             )) do
        p { 'We can help your partnership help everyone work together to produce a high quality and constantly updated website that\'s proven to work even in areas left behind by other digital initiatives.' }
        p { 'This information helps communities work better together, improves health outcomes, and saves everyone time manually collating information.' }
      end
      div(class: 'center') do
        link_to 'Our story', our_story_path, class: 'btn btn--big btn--home-3 btn--mt'
        link_to 'See it in action', find_placecal_path, class: 'btn btn--big btn--home-3 btn--mt'
      end
    end
  end

  def render_steps
    render Components::Steps.new(
      steps: [
        { id: 1, content: '<p>We have a chat on the phone to get the ball rolling, and set a time to come and show you how it works.</p>', image_alt: 'Two people talking on the phone' },
        { id: 2, content: '<p>We help you enter all the information you already know about local groups into PlaceCal.</p>', image_alt: 'Two people entering information into PlaceCal' },
        { id: 3, content: '<p>Next, we convert all the events you know about into an electronic calendar, and import the infomation into PlaceCal.</p>', image_alt: 'A noticeboard in a community centre' },
        { id: 4, content: '<p>You then have all the tools you need to get the rest of your neighbourhood connected.</p><p>(With ongoing support from us of course!)</p>', image_alt: 'A community worker waving to a resident' }
      ]
    )
  end

  def render_impact
    div(class: 'card card--split card--plain impact') do
      div(class: 'card__title') do
        h2(class: 'center') { 'How PlaceCal has helped' }
      end
      div(class: 'card__body') do
        h3(class: 'alt-title-small center') { "We've made organising community festivals and bringing people together a breeze." }
        figure do
          image_tag('http://placedog.net/600/400?random&i=1', class: 'rounded')
          figcaption { 'Image credit and title' }
        end
        div(class: 'impact__cols') do
          p { 'Community partnerships, social prescribers and neighbourhood teams in our pilot areas have been able to collaborate quickly and easily, enabling an unprecedented level of coordination.' }
          p { "The time and money savings from PlaceCal mean we've been able to focus on organising collaborative community festivals across multiple venues rather than simply struggling to find out what's on." }
        end
      end
      div(class: 'card__body') do
        h3(class: 'alt-title-small center') { "We've made the best listings in the whole city for our area, increasing neighbourhood wealth and health." }
        figure do
          image_tag('http://placedog.net/600/400?random&i=2', class: 'rounded')
          figcaption { 'Hulme Winter Festival leaflets' }
        end
        div(class: 'impact__cols') do
          p { 'Residents in Hulme have access to a constantly updated, high quality and trusted community resource with access to dozens of groups and over 200 events a week. The city council and housing associations struggle to even publish 10.' }
          p { "This tackles social isolation and loneliness at the root level by making it easy for everyone to find something to do. We've also used the information to create and deliver physical mailouts using information gathered through PlaceCal — something which would be simply impossible for each group working alone." }
        end
      end
    end
  end
end
