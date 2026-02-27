# frozen_string_literal: true

class Components::Steps < Components::Base
  prop :steps, Array
  prop :start_message, _Nilable(String), default: nil
  prop :end_message, _Nilable(String), default: nil

  def after_initialize
    @start_message ||= "Nothing is connected! People don't know where to go."
    @end_message ||= "Problem solved: everyone's connected and it's easy to find out what's happening!"
  end

  def view_template
    div(class: 'card card--split card--plain steps center') do
      render_header
      render_start_section
      render_steps_list
      render_end_section
      render_cta
    end
  end

  private

  def render_header
    div(class: 'card__title') do
      h2 { 'How it works for community groups' }
    end
  end

  def render_start_section
    div(class: 'card__body card__body--wide') do
      image_tag('home/how/start.png', alt: 'A diagram of a disconected neighbourhood', class: 'steps__image')
      div(class: 'steps__caption') { p(class: 'center') { @start_message } }
    end
  end

  def render_steps_list
    @steps.each do |step|
      div(class: 'card__body') do
        image_tag("home/how/#{step[:id]}.png", alt: step[:image_alt], class: 'steps__image steps__image--numeral')
        div(class: 'steps__caption') { raw(safe(step[:content])) }
      end
    end
  end

  def render_end_section
    div(class: 'card__body card__body--wide') do
      div(class: 'steps__caption') { p(class: 'center') { @end_message } }
      image_tag('home/how/end.png', alt: 'A diagram of a connected neighbourhood', class: 'steps__image')
      br
    end
  end

  def render_cta
    br
    link_to('Check out our handbook', 'https://handbook.placecal.org', class: 'btn btn--big btn--home-4')
    br(class: 'half')
  end
end
