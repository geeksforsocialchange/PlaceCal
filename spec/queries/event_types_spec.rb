# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventTypes do
  def from(query) = described_class.from_params(ActionController::Parameters.new(Rack::Utils.parse_nested_query(query)))

  describe ".from_params" do
    it "ticks every type when nothing is submitted" do
      expect(from("")).to be_all
    end

    it "reads the ticked types, in a fixed order" do
      expect(from("types[]=&types[]=long_running&types[]=one_off").to_a).to eq(%w[one_off long_running])
    end

    it "reads the form's blank types[] alone as none ticked" do
      expect(from("types[]=").to_a).to eq([])
    end

    it "ignores unknown or malformed types" do
      expect(from("types[]=parties&types[]=repeating").to_a).to eq(%w[repeating])
      expect(from("types[a]=b").to_a).to eq([])
      expect(from("types=long_running").to_a).to eq(%w[long_running])
    end

    {
      "repeating=on" => %w[one_off repeating long_running],
      "repeating=off" => %w[one_off long_running],
      "repeating=only" => %w[repeating],
      "long_running=off" => %w[one_off repeating],
      "long_running=only" => %w[long_running],
      "repeating=off&long_running=off" => %w[one_off],
      "repeating=only&long_running=only" => [],
      "repeating=sometimes" => %w[one_off repeating long_running]
    }.each do |query, types|
      it "maps the old #{query} onto #{types.inspect}" do
        expect(from(query).to_a).to eq(types)
      end
    end

    it "prefers types over the old params" do
      expect(from("types[]=one_off&repeating=only").to_a).to eq(%w[one_off])
    end
  end

  describe "#to_params" do
    it "is empty for the default, so default links stay as they were" do
      expect(described_class.all.to_params).to eq({})
    end

    it "lists the ticked types, or a blank one for none" do
      expect(described_class.new(%w[repeating]).to_params).to eq(types: %w[repeating])
      expect(described_class.new([]).to_params).to eq(types: [""])
    end

    it "round-trips through a query string" do
      [[], %w[one_off], %w[one_off repeating]].each do |types|
        expect(from(described_class.new(types).to_params.to_query).to_a).to eq(types)
      end
    end
  end
end
