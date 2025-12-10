# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CalendarsHelper, type: :helper do
  # NOTE: The original test had a FIXME noting an ActionView bug
  # causing infinite call loops. The test was commented out.
  # Leaving this as a placeholder for future implementation.

  let(:root) { create(:root) }
  let(:partners) { create_list(:partner, 3) }

  # test 'options_for_location only shows partners with addresses' do
  # FIXME: there is a bug in ActionView where it gets itself into an
  #   infinite call loop and StackOverflows
  # end
end
