# frozen_string_literal: true

module Admin
  class SourceInputComponent < ViewComponent::Base
    include SvgIconsHelper

    def initialize(form:, test_url:, show_importer: true)
      super()
      @form = form
      @test_url = test_url
      @show_importer = show_importer
    end

    private

    attr_reader :form, :test_url, :show_importer
  end
end
