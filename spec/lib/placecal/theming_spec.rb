# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaceCal::Theming do
  let(:widget) do
    allow(described_class).to receive(:register)

    Class.new(Components::Base) do
      theme_scope :spec_widget, parts: %i[root item_label], variants: { root: %i[wide] }, states: { root: %i[open closed] }

      def view_template
        div(**part(:root, variant: :wide, state: :open, class: "p-2", data: { controller: "x" }, data_turbo: "false")) do
          span(**part(:item_label)) { "Label" }
        end
      end
    end
  end

  def html(component) = Nokogiri::HTML.fragment(component.call)

  def scoped(template)
    allow(described_class).to receive(:register)
    Class.new(Components::Base) do
      theme_scope :spec_widget, parts: %i[root]
      define_method(:view_template, &template)
    end
  end

  it "marks parts with their scope and part in kebab-case" do
    label = html(widget.new).at_css("span")

    expect(label["data-scope"]).to eq("spec-widget")
    expect(label["data-part"]).to eq("item-label")
  end

  it "keeps the caller's own attributes, data hash and data_ keys alike" do
    root = html(widget.new).at_css("div")

    expect(root["class"]).to eq("p-2")
    expect(root["data-controller"]).to eq("x")
    expect(root["data-turbo"]).to eq("false")
    expect(root["data-part"]).to eq("root")
  end

  it "renders a variant and a state" do
    root = html(widget.new).at_css("div")

    expect(root["data-variant"]).to eq("wide")
    expect(root["data-state"]).to eq("open")
  end

  it "raises on a part, variant or state the scope does not declare" do
    templates = [-> { div(**part(:rot)) }, -> { div(**part(:root, variant: :wide)) }, -> { div(**part(:root, state: :open)) }]

    templates.each { |template| expect { scoped(template).new.call }.to raise_error(described_class::UndeclaredPart) }
  end

  it "raises on a part in a component without a scope" do
    unscoped = Class.new(Components::Base) { def view_template = div(**part(:root)) }

    expect { unscoped.new.call }.to raise_error(described_class::UndeclaredPart)
  end

  it "lists every declared scope, including views', in the contract" do
    contract = described_class.contract

    expect(contract.keys).to include("hero", "event", "event-details", "pill", "link", "button", "ruled-heading")
    expect(contract["event"]).to include(states: { "root" => %w[online] })
    expect(contract["event"][:variants]).to include("root" => %w[card page], "detail" => include("date", "time"))
    expect(contract["hero"][:parts]).to include("root", "standfirst-detail")
  end

  it "names only tokens core defines" do
    defined_tokens = Rails.root.join("app/tailwind/public/_theme.css").read.scan(/^\s*(--[a-z0-9-]+):/).flatten

    described_class.scopes.each_value do |scope|
      expect(scope.tokens.map(&:to_s) - defined_tokens).to be_empty, "#{scope.name} names undefined tokens"
    end
  end
end
