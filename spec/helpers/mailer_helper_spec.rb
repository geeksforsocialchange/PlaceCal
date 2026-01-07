# frozen_string_literal: true

require "rails_helper"

RSpec.describe MailerHelper do
  let(:view_class) do
    Class.new do
      include MailerHelper
    end
  end
  let(:view) { view_class.new }

  describe "#greeting_text" do
    it "returns Hello with no set name" do
      user = User.new

      output = view.greeting_text(user)
      expect(output).to eq("Hello")
    end

    it "returns Hello with first name when only first name is set" do
      user = User.new(first_name: "Alpha")

      output = view.greeting_text(user)
      expect(output).to eq("Hello Alpha")
    end

    it "returns Hello with last name when only last name is set" do
      user = User.new(last_name: "Beta")

      output = view.greeting_text(user)
      expect(output).to eq("Hello Beta")
    end

    it "returns Hello with full name when both names are set" do
      user = User.new(first_name: "Cappa", last_name: "Beta")

      output = view.greeting_text(user)
      expect(output).to eq("Hello Cappa Beta")
    end
  end
end
