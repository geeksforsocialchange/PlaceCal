# frozen_string_literal: true

class FullWidthActionComponentPreview < ViewComponent::Preview
  # @label Blue
  def blue
    render(FullWidthActionComponent.new(
             title: 'Ready to get started?',
             link_text: 'Find your local PlaceCal',
             link_url: '/find-placecal',
             color: 'blue'
           ))
  end

  # @label Green
  def green
    render(FullWidthActionComponent.new(
             title: 'Want to add your events?',
             link_text: 'Become a partner',
             link_url: '/join',
             color: 'green'
           ))
  end

  # @label Cream
  def cream
    render(FullWidthActionComponent.new(
             title: 'Need help getting started?',
             link_text: 'Contact us',
             link_url: '/contact',
             color: 'cream'
           ))
  end

  # @label Red
  def red
    render(FullWidthActionComponent.new(
             title: 'Important announcement',
             link_text: 'Read more',
             link_url: '/news',
             color: 'red'
           ))
  end
end
