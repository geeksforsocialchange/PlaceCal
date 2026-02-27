# frozen_string_literal: true

class Components::Steps < Components::Base
  prop :steps, _Any
  prop :start_message, _Nilable(String), default: nil
  prop :end_message, _Nilable(String), default: nil

  def after_initialize
    @start_message ||= "Nothing is connected! People don't know where to go."
    @end_message ||= "Problem solved: everyone's connected and it's easy to find out what's happening!"
  end

  def view_template # rubocop:disable Metrics/MethodLength
    div(class: 'card card--split card--plain steps center') do
      div(class: 'card__title') do
        h2 { 'How it works for community groups' }
      end

      div(class: 'card__body card__body--wide') do
        image_tag('home/how/start.png', alt: 'A diagram of a disconected neighbourhood', class: 'steps__image')
        div(class: 'steps__caption') do
          p(class: 'center') { @start_message }
        end
      end

      @steps.each do |step|
        div(class: 'card__body') do
          image_tag("home/how/#{step[:id]}.png", alt: step[:image_alt], class: 'steps__image steps__image--numeral')
          div(class: 'steps__caption') do
            raw(safe(step[:content]))
          end
        end
      end

      div(class: 'card__body card__body--wide') do
        div(class: 'steps__caption') do
          p(class: 'center') { @end_message }
        end
        image_tag('home/how/end.png', alt: 'A diagram of a connected neighbourhood', class: 'steps__image')
        br
      end

      br
      link_to('Check out our handbook', 'https://handbook.placecal.org', class: 'btn btn--big btn--home-4')
      br(class: 'half')
    end
  end
end
