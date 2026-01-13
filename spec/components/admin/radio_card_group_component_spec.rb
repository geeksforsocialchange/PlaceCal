# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::RadioCardGroupComponent, type: :component do
  let(:model) { Struct.new(:strategy).new("event_override") }
  let(:template) { ActionView::Base.empty }
  let(:form) do
    ActionView::Helpers::FormBuilder.new(:calendar, model, template, {})
  end

  it "renders radio buttons for each value" do
    render_inline(described_class.new(form: form, attribute: :strategy, values: %w[event_override place]))
    expect(page).to have_css("input[type='radio']", count: 2)
  end

  it "renders labels for each value" do
    render_inline(described_class.new(form: form, attribute: :strategy, values: %w[online room_number]))
    expect(page).to have_text("Online")
    expect(page).to have_text("Room Number")
  end

  it "uses custom label method when provided" do
    label_method = ->(pair) { "Custom: #{pair[1]}" }
    render_inline(described_class.new(
                    form: form,
                    attribute: :strategy,
                    values: %w[test],
                    label_method: label_method
                  ))
    expect(page).to have_text("Custom: test")
  end

  it "renders with card styling" do
    render_inline(described_class.new(form: form, attribute: :strategy, values: %w[one]))
    expect(page).to have_css("label.rounded-lg.border.border-base-300")
  end

  it "has checked state styling" do
    render_inline(described_class.new(form: form, attribute: :strategy, values: %w[one]))
    expect(page).to have_css("label[class*='has-[:checked]:border-placecal-orange']")
  end

  it "renders correct radio button attributes" do
    render_inline(described_class.new(form: form, attribute: :strategy, values: %w[event_override]))
    expect(page).to have_css("input[type='radio'][name='calendar[strategy]'][value='event_override']")
  end

  it "selects current value" do
    render_inline(described_class.new(form: form, attribute: :strategy, values: %w[event_override place]))
    expect(page).to have_css("input[type='radio'][value='event_override'][checked]")
  end
end
