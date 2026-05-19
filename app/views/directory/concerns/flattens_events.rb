# frozen_string_literal: true

module Views::Directory::Concerns::FlattensEvents
  private

  def flat_events
    @flat_events ||= if @upcoming_events.respond_to?(:each_pair)
                       @upcoming_events.values.flatten
                     else
                       Array(@upcoming_events)
                     end
  end
end
