# frozen_string_literal: true

# app/components/steps/steps_component.rb
class StepsComponent < ViewComponent::Base
  def initialize(steps:, start_message: nil, end_message: nil)
    super
    @steps = steps
    @start_message = start_message ||= "Nothing is connected! People don't know where to go."
    @end_message = end_message ||= "Problem solved: everyone's connected and it's easy to find out what's happening!"
  end
end
