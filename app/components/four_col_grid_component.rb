# frozen_string_literal: true

class FourColGridComponent < ViewComponent::Base
  def initialize(options = { partnershipCards: false })
    super
    @class = options[:partnershipCards] ? 'four_col_grid--larger' : 'four_col_grid'
  end
end
