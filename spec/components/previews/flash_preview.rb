# frozen_string_literal: true

class FlashPreview < Lookbook::Preview
  # @label Success message
  def success
    render Components::Flash.new(flash_messages: { notice: "Partner saved successfully." })
  end

  # @label Error message
  def error
    render Components::Flash.new(flash_messages: { error: "Something went wrong. Please try again." })
  end

  # @label Multiple messages
  def multiple
    render Components::Flash.new(flash_messages: { notice: "Calendar imported.", alert: "Some events could not be parsed." })
  end
end
