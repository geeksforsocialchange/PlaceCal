# frozen_string_literal: true

require "rails_helper"

RSpec.describe Views::Admin::Partners::FormTabSettings, type: :phlex do
  # Renders the settings tab inside a SimpleForm form so the toggle's
  # form helpers resolve, returning a Capybara node for the markup.
  def render_settings(partner)
    component = described_class
    wrapper = Class.new(Views::Admin::Base) do
      define_method(:initialize) { |p| @partner = p }
      define_method(:view_template) do
        simple_form_for(@partner, url: "/x") do |form|
          render component.new(form:)
        end
      end
    end

    html = wrapper.new(partner).render_in(view_context)
    Capybara::Node::Simple.new(html)
  end

  # The component calls policy(partner) for the URL/slug section; stub it so the
  # spec does not depend on an authenticated user.
  let(:permitted_attributes) { %i[slug] }

  let(:view_context) do
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    context = controller.view_context
    permitted = permitted_attributes
    permissive_policy = Struct.new(:record) do
      define_method(:permitted_attributes) { permitted }
      def destroy? = false
    end
    context.define_singleton_method(:policy) { |record| permissive_policy.new(record) }
    context
  end

  context "when event matching is enabled" do
    let(:partner) { Partner.new(name: "Test", can_be_assigned_events: true) }

    it "checks the toggle" do
      page = render_settings(partner)
      expect(page).to have_css("input#partner_can_be_assigned_events[checked]")
    end

    it "marks the enabled label active and the disabled label inactive" do
      page = render_settings(partner)
      expect(page).to have_css("#event-matching-label-enabled[data-active='true']")
      expect(page).to have_css("#event-matching-label-disabled[data-active='false']")
    end
  end

  context "when event matching is disabled" do
    let(:partner) { Partner.new(name: "Test", can_be_assigned_events: false) }

    it "leaves the toggle unchecked" do
      page = render_settings(partner)
      expect(page).to have_no_css("input#partner_can_be_assigned_events[checked]")
    end

    it "marks both labels inactive" do
      page = render_settings(partner)
      expect(page).to have_css("#event-matching-label-disabled[data-active='false']")
      expect(page).to have_css("#event-matching-label-enabled[data-active='false']")
    end
  end

  context "with the moderation section" do
    let(:permitted_attributes) { %i[slug hidden] }

    it "marks Visible active and Hidden inactive when the partner is visible" do
      page = render_settings(build_stubbed(:partner, hidden: false))
      expect(page).to have_css("#partner-visibility-label-visible[data-active='true']")
      expect(page).to have_css("span[data-active='false']", text: I18n.t("admin.labels.hidden"))
    end

    it "marks both labels inactive when the partner is hidden" do
      page = render_settings(build_stubbed(:partner, hidden: true))
      expect(page).to have_css("#partner-visibility-label-visible[data-active='false']")
    end
  end
end
