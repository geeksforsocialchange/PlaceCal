# frozen_string_literal: true

class StepsComponent  < ViewComponent::Base
  attr_reader :start_message
  attr_reader :end_message
  attr_reader :steps
  
  def initialize(start_message: nil, end_message: nil, steps:)
    @start_message = start_message || "Nothing is connected! People don't know where to go."
    @end_message = end_message || "Problem solved: everyone's connected and it's easy to find out what's happening!"
    @steps = steps
  end
  
end
