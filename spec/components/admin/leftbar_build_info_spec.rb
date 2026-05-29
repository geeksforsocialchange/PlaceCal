# frozen_string_literal: true

require "rails_helper"

# Covers the build-info widget in the admin sidebar
# (Views::Layouts::Admin::Application#leftbar_build_info). The surrounding
# layout needs an authenticated controller, so we exercise just the build-info
# fragment via a thin Phlex subclass.
RSpec.describe Views::Layouts::Admin::Application, type: :component do
  # Renders only the build-info fragment (a private method on the layout).
  let(:build_info_component) do
    Class.new(described_class) do
      def view_template
        leftbar_build_info
      end
    end
  end

  context "when APP_VERSION is set" do
    before do
      stub_const("ENV", ENV.to_hash.merge("APP_VERSION" => "v0.9.1"))
    end

    it "shows the version label linking to the release tag" do
      render_inline(build_info_component.new)

      link = page.find("a", text: "v0.9.1")
      expect(link[:href])
        .to eq("https://github.com/geeksforsocialchange/PlaceCal/releases/tag/v0.9.1")
    end

    it "keeps the Build label" do
      render_inline(build_info_component.new)

      expect(page).to have_text(I18n.t("admin.leftbar.build"))
    end
  end

  context "when neither APP_VERSION nor GIT_REV is set" do
    before do
      env = ENV.to_hash
      env.delete("APP_VERSION")
      env.delete("GIT_REV")
      stub_const("ENV", env)
    end

    it "falls back to a 'dev' build label linking to the repo" do
      render_inline(build_info_component.new)

      link = page.find("a", text: "dev")
      expect(link[:href]).to eq("https://github.com/geeksforsocialchange/PlaceCal")
    end
  end
end
