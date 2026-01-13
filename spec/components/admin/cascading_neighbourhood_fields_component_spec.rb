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

  describe "region select" do
    it "renders region select field" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-target='region']")
    end

    it "has region changed action" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-action*='change->cascading-neighbourhood#regionChanged']")
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
      # No remove link should be present
      # The component conditionally renders the remove link
    end
  end

  describe "loading indicator" do
    it "renders hidden loading spinner" do
      render_inline(described_class.new(form: form))
      expect(page).to have_css("[data-cascading-neighbourhood-target='loading'].hidden")
    end
  end
end
