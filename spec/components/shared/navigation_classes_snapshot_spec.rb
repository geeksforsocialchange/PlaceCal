# frozen_string_literal: true

require "rails_helper"

# Pins every class attribute the navigation renders in each context.
# Regenerate after an intended class change with UPDATE_SNAPSHOTS=1.
RSpec.describe Components::Shared::Navigation, type: :component do
  let(:snapshot_path) { Rails.root.join("spec/fixtures/navigation_classes.yml") }
  let(:navigation) do
    [
      [I18n.t("navigation.site.home"), "/"],
      [I18n.t("navigation.site.events"), "/events"],
      [I18n.t("navigation.site.partners"), "/partners"]
    ]
  end
  let(:site) { build_stubbed(:site, name: "Snapshot Site", slug: "snapshot-site") }

  def cta_theme
    theme = PlaceCal::Theme.new(:fixture)
    theme.nav_cta "navigation.site.events", "https://example.org/donate"
    theme.menu_label true
    theme
  end

  def class_attributes(component)
    render_inline(component).native.css("[class]").to_h { |node| [node.path, node["class"]] }
  end

  def rendered_snapshot
    Current.theme = PlaceCal::Theme::NONE
    directory = class_attributes(described_class.new(navigation:, site: nil))
    plain_site = class_attributes(described_class.new(navigation:, site:))

    Current.theme = cta_theme
    cta_site = class_attributes(described_class.new(navigation:, site:))

    # The props Components::Join::Header passes.
    Current.theme = PlaceCal::Theme::NONE
    join = class_attributes(described_class.new(navigation:, site: nil, cta_label: I18n.t("join.nav.book_demo"),
                                                cta_path: "/demo", home_heading: false))

    { "directory" => directory, "site" => plain_site, "site_with_theme_cta" => cta_site, "join" => join }
  end

  it "renders the same class attributes in every context" do
    snapshot = rendered_snapshot
    File.write(snapshot_path, snapshot.to_yaml) if ENV["UPDATE_SNAPSHOTS"]

    expect(File).to exist(snapshot_path)
    expect(snapshot).to eq(YAML.safe_load_file(snapshot_path))
  end
end
