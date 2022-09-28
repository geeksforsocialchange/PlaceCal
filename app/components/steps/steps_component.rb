# frozen_string_literal: true

# app/components/steps/steps_component.rb
class StepsComponent < MountainView::Presenter
  property :start_message,
           default: "Nothing is connected! People don't know where to go."
  property :end_message,
           default:
             "Problem solved: everyone's connected and it's easy to find out what's happening!"
  property :steps
end
