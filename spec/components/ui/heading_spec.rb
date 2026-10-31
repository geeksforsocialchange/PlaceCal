# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::UI::Heading, type: :component do
  it "renders the heading level it is given" do
    render_inline(described_class.new(level: 3, size: :subhead, id: "faq")) { "Questions" }

    expect(page).to have_css("h3#faq", text: "Questions")
  end

  it "takes the colour around it with tone: :inherit" do
    render_inline(described_class.new(size: :display, tone: :inherit)) { "Ready to start?" }

    expect(page).to have_css("h2.text-display.leading-tight", text: "Ready to start?")
    expect(page).to have_no_css("h2[class*='text-foreground']")
  end

  it "balances a wrapping heading when asked" do
    render_inline(described_class.new(balance: true)) { "Where it all began" }

    expect(page).to have_css("h2.text-balance")
  end

  it "rejects a level outside h1 to h4" do
    expect { described_class.new(level: 5) }.to raise_error(Literal::TypeError)
  end

  it "rejects a spacing that isn't one of its steps" do
    expect { described_class.new(spacing: :huge) }.to raise_error(Literal::TypeError)
  end
end
