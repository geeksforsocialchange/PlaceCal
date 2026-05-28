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
          render component.new(form: form)
        end
      end
    end

    html = wrapper.new(partner).render_in(view_context)
    Capybara::Node::Simple.new(html)
  end

  # The component calls policy(partner) for the URL/slug section; stub it so the
  # spec does not depend on an authenticated user.
  let(:view_context) do
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    context = controller.view_context
    permissive_policy = Struct.new(:record) do
      def permitted_attributes = %i[slug]
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

    it "renders the enabled label prominently and the disabled label faded" do
      page = render_settings(partner)
      expect(page).to have_css("#event-matching-label-enabled.text-success")
      expect(page).to have_css("#event-matching-label-disabled.text-base-content\\/40")
    end
  end

  context "when event matching is disabled" do
    let(:partner) { Partner.new(name: "Test", can_be_assigned_events: false) }

    it "leaves the toggle unchecked" do
      page = render_settings(partner)
      expect(page).to have_no_css("input#partner_can_be_assigned_events[checked]")
    end

    it "renders the disabled label prominently and the enabled label faded" do
      page = render_settings(partner)
      expect(page).to have_css("#event-matching-label-disabled.text-base-content")
      expect(page).to have_css("#event-matching-label-enabled.text-base-content\\/40")
    end
  end
end
