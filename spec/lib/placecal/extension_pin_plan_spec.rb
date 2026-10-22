# frozen_string_literal: true

require "rails_helper"
require_relative "../../../lib/placecal/extension_pin_plan"

RSpec.describe PlaceCal::ExtensionPinPlan do
  let(:name) { "placecal-theme-mossley" }

  def plan(current: "0.1.0", latest: "0.2.0", target_prs: [], open_prs: [])
    described_class.call(name:, current:, latest:, target_prs:, open_prs:)
  end

  def pin_pr(number, version)
    { number:, head: "extensions/#{name}-v#{version}" }
  end

  it "opens a PR when a newer tag has no PR yet" do
    result = plan

    expect(result.action).to eq(:open)
    expect(result.branch).to eq("extensions/#{name}-v0.2.0")
    expect(result.close).to be_empty
  end

  it "skips when the pin is already the latest tag" do
    result = plan(current: "0.2.0", latest: "0.2.0")

    expect(result.action).to eq(:skip)
    expect(result.reason).to eq("v0.2.0 is the latest")
  end

  it "skips when the gem has no release tags" do
    expect(plan(latest: nil).action).to eq(:skip)
  end

  it "skips a version whose PR is already open" do
    result = plan(target_prs: [{ number: 12, state: "OPEN" }])

    expect(result.action).to eq(:skip)
    expect(result.reason).to eq("PR #12 for v0.2.0 is already open")
  end

  it "does not reopen a version whose PR was closed without merging" do
    result = plan(target_prs: [{ number: 12, state: "CLOSED" }])

    expect(result.action).to eq(:skip)
    expect(result.reason).to eq("PR #12 for v0.2.0 was closed without merging")
  end

  it "does not reopen a version whose PR was merged" do
    result = plan(target_prs: [{ number: 12, state: "MERGED" }])

    expect(result.action).to eq(:skip)
    expect(result.reason).to eq("PR #12 for v0.2.0 was merged")
  end

  it "prefers an open PR over an earlier closed one on the same branch" do
    result = plan(target_prs: [{ number: 11, state: "CLOSED" }, { number: 12, state: "OPEN" }])

    expect(result.reason).to eq("PR #12 for v0.2.0 is already open")
  end

  it "closes the open PR for an older version when opening one for a newer tag" do
    open_prs = [pin_pr(10, "0.1.1"), pin_pr(20, "0.1.0"), { number: 30, head: "extensions/placecal-theme-other-v0.1.1" },
                { number: 40, head: "feature/unrelated" }]

    result = plan(open_prs:)

    expect(result.action).to eq(:open)
    expect(result.close).to contain_exactly({ number: 10, version: "0.1.1" }, { number: 20, version: "0.1.0" })
    expect(result.superseded_by).to eq("0.2.0")
  end

  it "closes older open PRs while the newest version's PR is already open" do
    result = plan(target_prs: [{ number: 12, state: "OPEN" }], open_prs: [pin_pr(12, "0.2.0"), pin_pr(10, "0.1.1")])

    expect(result.close).to eq([{ number: 10, version: "0.1.1" }])
  end

  it "leaves older open PRs alone when the newest version's PR was closed" do
    result = plan(target_prs: [{ number: 12, state: "CLOSED" }], open_prs: [pin_pr(10, "0.1.1")])

    expect(result.close).to be_empty
  end

  it "closes open PRs for versions the Gemfile already pins or is past" do
    result = plan(current: "0.2.0", latest: "0.2.0", open_prs: [pin_pr(10, "0.1.1"), pin_pr(12, "0.2.0")])

    expect(result.close.pluck(:number)).to contain_exactly(10, 12)
    expect(result.superseded_by).to eq("0.2.0")
  end
end
