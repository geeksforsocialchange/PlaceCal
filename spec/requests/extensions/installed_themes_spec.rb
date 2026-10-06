# frozen_string_literal: true

require "rails_helper"

# The fixture theme cannot catch a core change that breaks a real theme gem.
RSpec.describe "Installed theme homepages", type: :request do
  def self.installed_themes
    PlaceCal::Extensions.themes.select { |theme| theme.homepage_view_class && theme.name != "example_theme" }
  end

  installed_themes.each do |theme|
    it "renders the #{theme.name} homepage with an event, a partner and a site admin" do
      ward = create(:riverside_ward)
      site = create(:site, slug: "themed", theme: theme.name, url: "https://themed.lvh.me", site_admin: create(:root_user))
      site.neighbourhoods << ward
      partner = create(:partner, address: create(:address, neighbourhood: ward))
      create(:event, organiser: partner, address: partner.address)

      get "http://themed.lvh.me"

      expect(response).to be_successful
    end
  end

  it "covers at least one installed theme" do
    expect(self.class.installed_themes).not_to be_empty
  end
end

RSpec.describe "Legacy kit names" do
  Components::LEGACY_KIT_NAMES.each do |name, target|
    it "keeps #{name}() pointing at Components::#{target}" do
      expect(Components.const_get(target)).to be < Phlex::HTML
      expect(Views::Base.instance_methods).to include(name)
    end
  end
end
