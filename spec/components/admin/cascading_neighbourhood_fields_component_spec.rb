# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CascadingNeighbourhoodFieldsComponent, type: :component do
  let(:partner) { Partner.new }
  let(:template) { ActionView::Base.empty }
  let(:form) do
    ActionView::Helpers::FormBuilder.new(:partner, partner, template, {})
  end

  it "renders the cascading neighbourhood fields" do
    render_inline(described_class.new(form: form))
    expect(page).to have_css(".nested-fields")
  end

  it "includes cascading-neighbourhood controller" do
    render_inline(described_class.new(form: form))
    expect(page).to have_css("[data-controller='cascading-neighbourhood']")
  end

  it "renders as a card" do
    render_inline(described_class.new(form: form))
    expect(page).to have_css(".card")
  end

  it "shows 'New Service Area' header" do
    render_inline(described_class.new(form: form))
    expect(page).to have_text(I18n.t("admin.service_areas.new_area"))
  end

  describe "country select" do
    it "renders country select field" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-target='country']")
    end

    it "has country changed action" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-action*='change->cascading-neighbourhood#countryChanged']")
    end

    it "is visible by default" do
      render_inline(described_class.new(form: form))
      expect(page).not_to have_css("select[data-cascading-neighbourhood-target='country'].hidden")
    end
  end

  describe "region select" do
    it "renders region select field" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-target='region']")
    end

    it "has region changed action" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-action*='change->cascading-neighbourhood#regionChanged']")
    end

    it "is disabled by default" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("select[data-cascading-neighbourhood-target='region'][disabled]")
    end
  end

  describe "county select" do
    it "renders county select field" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-target='county']")
    end

    it "is disabled by default" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("select[data-cascading-neighbourhood-target='county'][disabled]")
    end

    it "row is hidden by default" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-target='countyRow'].hidden")
    end
  end

  describe "district select" do
    it "renders district select field" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-target='district']")
    end

    it "is disabled by default" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("select[data-cascading-neighbourhood-target='district'][disabled]")
    end

    it "row is hidden by default" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-target='districtRow'].hidden")
    end
  end

  describe "ward select" do
    it "renders ward select field" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-target='ward']")
    end

    it "is disabled by default" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("select[data-cascading-neighbourhood-target='ward'][disabled]")
    end

    it "row is hidden by default" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-target='wardRow'].hidden")
    end
  end

  describe "placeholder values from locale" do
    it "includes country placeholder data attribute" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-placeholder-country-value]")
    end

    it "includes region placeholder data attribute" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-placeholder-region-value]")
    end

    it "includes county placeholder data attribute" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-placeholder-county-value]")
    end

    it "includes district placeholder data attribute" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-placeholder-district-value]")
    end

    it "includes ward placeholder data attribute" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-placeholder-ward-value]")
    end
  end

  describe "hidden fields" do
    it "renders neighbourhood_id hidden field" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("input[type='hidden'][data-cascading-neighbourhood-target='output']", visible: :hidden)
    end

    it "renders relation_type hidden field when provided" do
      render_inline(described_class.new(form: form, relation_type: "service_area"))
      expect(page).to have_css("input[type='hidden'][value='service_area']", visible: :hidden)
    end

    it "does not render relation_type when not provided" do
      render_inline(described_class.new(form: form))
      expect(page).not_to have_css("input[name*='relation_type']", visible: :hidden)
    end
  end

  describe "remove button" do
    it "shows remove button when show_remove is true" do
      render_inline(described_class.new(form: form, show_remove: true))
      # The nested_form_remove_link helper renders a link with the trash icon
      expect(page).to have_css("svg") # trash icon
    end

    it "hides remove button when show_remove is false" do
      render_inline(described_class.new(form: form, show_remove: false))
      # No remove link should be present - check there's no btn-error (trash button class)
      expect(page).not_to have_css(".btn-error")
    end
  end

  describe "loading indicator" do
    it "renders hidden loading spinner" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-target='loading'].hidden")
    end
  end

  describe "layout" do
    it "renders labels for each field" do
      render_inline(described_class.new(form: form))
      expect(page).to have_text(I18n.t("admin.cascading_neighbourhood.country"))
      expect(page).to have_text(I18n.t("admin.cascading_neighbourhood.region"))
      expect(page).to have_text(I18n.t("admin.cascading_neighbourhood.county"))
      expect(page).to have_text(I18n.t("admin.cascading_neighbourhood.area"))
      expect(page).to have_text(I18n.t("admin.cascading_neighbourhood.ward"))
    end

    it "uses flex layout for label/field alignment" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css(".flex.items-center.gap-3")
    end
  end
end
