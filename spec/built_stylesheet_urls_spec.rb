# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Built stylesheet URLs" do
  %w[public_tailwind.css admin_tailwind.css].each do |stylesheet|
    it "resolves every relative url() in #{stylesheet} to an asset" do
      asset = Rails.application.assets.load_path.find(stylesheet)
      css = Rails.application.assets.compilers.compile(asset)
      relative = css.scan(/url\(\s*["']?([^"')]+)/).flatten.grep_v(%r{\A(/|#|%23|data:|https?:)})

      expect(relative).to be_empty, "Unresolved asset URLs in #{stylesheet}: #{relative.uniq.join(', ')}"
    end
  end
end
