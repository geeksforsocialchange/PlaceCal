# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Admin::RadioCardGroup, type: :phlex do
  context "with user roles" do
    it "renders the dynamically translated description for every role" do
      form = ActionView::Helpers::FormBuilder.new(:user, build(:user), view_context, {})
      render_inline(described_class.new(form:, attribute: :role, values: User.role.values,
                                        i18n_scope: "admin.users.roles"))

      User.role.values.each do |role|
        expect(page).to have_css("label", text: I18n.t("admin.users.roles.#{role}", raise: true))
      end
    end
  end

  context "with calendar strategies" do
    it "renders the dynamically translated description for every strategy" do
      form = ActionView::Helpers::FormBuilder.new(:calendar, build(:calendar), view_context, {})
      render_inline(described_class.new(form:, attribute: :strategy, values: Calendar.strategy.values,
                                        i18n_scope: "admin.calendars.strategy"))

      Calendar.strategy.values.each do |strategy|
        expect(page).to have_css("label", text: I18n.t("admin.calendars.strategy.#{strategy}", raise: true))
      end
    end
  end
end
