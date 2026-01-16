# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ToggleCardComponent, type: :component do
  let(:model) { Struct.new(:is_published).new(false) }
  let(:template) { ActionView::Base.empty }
  let(:form) do
    ActionView::Helpers::FormBuilder.new(:site, model, template, {})
  end

  it "renders checkbox with title" do
    render_inline(described_class.new(form: form, attribute: :is_published, title: "Published"))
    expect(page).to have_css("input[type='checkbox']")
    expect(page).to have_text("Published")
  end

  it "renders description when provided" do
    render_inline(described_class.new(
                    form: form,
                    attribute: :is_published,
                    title: "Published",
                    description: "Make this site visible"
                  ))
    expect(page).to have_text("Make this site visible")
  end

  it "does not render description when not provided" do
    render_inline(described_class.new(form: form, attribute: :is_published, title: "Test"))
    expect(page).not_to have_css("p.text-sm.text-base-content\\/60")
  end

  it "renders with card styling" do
    render_inline(described_class.new(form: form, attribute: :is_published, title: "Test"))
    expect(page).to have_css("label.rounded-lg.border.border-base-300")
  end

  describe "variants" do
    it "uses success variant by default" do
      render_inline(described_class.new(form: form, attribute: :is_published, title: "Test"))
      expect(page).to have_css("input.checkbox-success")
      expect(page).to have_css("label[class*='has-[:checked]:border-success']")
    end

    it "supports warning variant" do
      render_inline(described_class.new(form: form, attribute: :is_published, title: "Test", variant: :warning))
      expect(page).to have_css("input.checkbox-warning")
      expect(page).to have_css("label[class*='has-[:checked]:border-warning']")
    end

    it "supports error variant" do
      render_inline(described_class.new(form: form, attribute: :is_published, title: "Test", variant: :error))
      expect(page).to have_css("input.checkbox-error")
      expect(page).to have_css("label[class*='has-[:checked]:border-error']")
    end
  end

  it "renders correct checkbox attributes" do
    render_inline(described_class.new(form: form, attribute: :is_published, title: "Test"))
    expect(page).to have_css("input[type='checkbox'][name='site[is_published]']")
  end
end
