# frozen_string_literal: true

class HelpCardPreview < Lookbook::Preview
  # @label Computer access
  def computer_access
    render Components::HelpCard.new(variant: :computer_access)
  end

  # @label Free wifi
  def free_wifi
    render Components::HelpCard.new(variant: :free_wifi)
  end

  # @label Getting help
  def getting_help
    render Components::HelpCard.new(variant: :getting_help)
  end

  # @notes The :adding_events variant requires a Site with a site_admin,
  # so it is not previewed here. It renders nothing when site is nil.
end
