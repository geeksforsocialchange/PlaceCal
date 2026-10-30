# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Heading, type: :component do
  it "renders the heading level it is given" do
    render_inline(described_class.new(level: 3, size: :subhead, id: "faq")) { "Questions" }

    expect(page).to have_css("h3#faq", text: "Questions")
  end

  it "rejects a level outside h1 to h4" do
    expect { described_class.new(level: 5) }.to raise_error(Literal::TypeError)
  end

  it "rejects a spacing that isn't one of its steps" do
    expect { described_class.new(spacing: :huge) }.to raise_error(Literal::TypeError)
  end
end
