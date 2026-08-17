# frozen_string_literal: true

require "rails_helper"

# Regression guard for #3058 ("My Permissions" icons scrambled for neighbourhood
# admins). Each permission card hardcodes its own icon, so this spec pins the
# icon-to-card mapping and the rendering order so they cannot drift apart.
RSpec.describe Views::Admin::Users::ProfileTabPermissions, type: :component do
  # Canonical SVG path data for each permission icon, read straight from the
  # icon set so the spec keeps passing if the icon artwork is updated while
  # still catching a wrong icon being wired to the wrong card.
  def icon_path(name)
    entry = SvgIconsHelper::ICONS[name]
    entry.is_a?(Hash) ? entry[:path] : entry
  end

  def profile_label(key)
    I18n.t("admin.users.profile.#{key}")
  end

  # The <path> d= value of every icon rendered inside a permission card header,
  # in document (top-to-bottom) order.
  def rendered_header_icon_paths
    page.all("div.bg-base-200\\/50 > div.flex.items-center svg > path").map { |p| p["d"] }
  end

  def render_for(user)
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user).and_return(user)

    template = ActionView::Base.empty
    form = ActionView::Helpers::FormBuilder.new(:user, user, template, {})
    render_inline(described_class.new(form: form))
  end

  context "with a neighbourhood admin who admins all resource types" do
    let(:user) do
      create(:neighbourhood_admin).tap do |u|
        u.partners << create(:partner)
        u.tags << create(:partnership)
        u.sites << create(:site)
        u.reload
      end
    end

    before { render_for(user) }

    it "renders one card per assigned resource type, in order" do
      titles = page.all("div.bg-base-200\\/50 h4").map(&:text)
      expect(titles).to eq(
        [
          profile_label("your_partners"),
          profile_label("your_neighbourhoods"),
          profile_label("your_partnerships"),
          profile_label("your_sites")
        ]
      )
    end

    it "shows each card's icon next to its matching heading, in order" do
      expect(rendered_header_icon_paths).to eq(
        [
          icon_path(:partner),
          icon_path(:map_pin),
          icon_path(:partnership),
          icon_path(:site)
        ]
      )
    end
  end

  context "with a neighbourhood admin who only has a neighbourhood" do
    let(:user) { create(:neighbourhood_admin) }

    before { render_for(user) }

    it "renders only the neighbourhoods card with the map pin icon" do
      titles = page.all("div.bg-base-200\\/50 h4").map(&:text)
      expect(titles).to eq([profile_label("your_neighbourhoods")])
      expect(rendered_header_icon_paths).to eq([icon_path(:map_pin)])
    end
  end
end
