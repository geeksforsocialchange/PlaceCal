# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PostgreSQL version" do
  def postgres_majors(path)
    Rails.root.join(path).read.scan(/^\s*image:\s*postgres:(\d+)/).flatten
  end

  it "is the same in CI as in production" do
    production = postgres_majors("config/deploy.yml")
    ci = Rails.root.glob(".github/workflows/*.yml").flat_map { |file| postgres_majors(file.relative_path_from(Rails.root)) }

    expect(production.size).to eq(1)
    expect(ci).to be_present.and(all(eq(production.first)))
  end
end
