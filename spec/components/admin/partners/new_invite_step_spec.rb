# frozen_string_literal: true

require "rails_helper"

# Regression coverage for issue #2991: the "Skip this step" checkbox in the new
# partner wizard had no id and its label had no matching `for`, so clicking the
# label did nothing and the control was inaccessible to screen readers.
#
# The full New view depends on `current_user` (in the location step), so this
# spec renders only the invite step in isolation via a thin subclass. The
# invite step takes a form argument but does not call any method on it.
RSpec.describe Views::Admin::Partners::New, type: :component do
  # Renders just the "Invite a Partner Admin" step so we can assert its markup
  # without the Devise/asset context the full wizard page requires.
  let(:invite_step_view) do
    Class.new(described_class) do
      def view_template
        render_step_invite(nil)
      end
    end
  end

  before do
    render_inline(invite_step_view.new(partner: Partner.new))
  end

  it "gives the skip-admin checkbox an id" do
    expect(page).to have_css("input[type='checkbox']#partner_skip_admin")
  end

  it "links the label to the skip-admin checkbox via matching for" do
    expect(page).to have_css("label[for='partner_skip_admin']")
  end

  it "uses the same value for the checkbox id and the label for" do
    checkbox = page.find("input[type='checkbox'][data-partner-wizard-target='skipAdminCheckbox']")
    label = page.find("label[for]", text: /Skip this step/)

    expect(checkbox[:id]).to be_present
    expect(label[:for]).to eq(checkbox[:id])
  end
end
