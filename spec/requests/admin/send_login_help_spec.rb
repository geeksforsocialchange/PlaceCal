# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin send login help", type: :request do
  let(:admin) { create(:root_user) }

  before { sign_in admin }

  describe "POST /users/:id/send_login_help" do
    it "re-sends the invitation when it was never accepted" do
      invited = User.new(email: "invited@example.com", skip_password_validation: true)
      invited.invite!
      ActionMailer::Base.deliveries.clear

      post send_login_help_admin_user_url(invited, host: admin_host)

      expect(response).to redirect_to(edit_admin_user_path(invited))
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq ["invited@example.com"]
      expect(email.subject).to match(/[Ii]nvit/)
    end

    it "sends a password reset for an accepted account" do
      user = create(:user)

      expect { post send_login_help_admin_user_url(user, host: admin_host) }
        .to change(ActionMailer::Base.deliveries, :count).by(1)

      email = ActionMailer::Base.deliveries.last
      expect(email.to).to eq [user.email]
      expect(user.reload.reset_password_token).to be_present
    end

    it "is denied for users the admin cannot manage" do
      sign_in create(:citizen_user)
      target = create(:user)

      post send_login_help_admin_user_url(target, host: admin_host)

      expect(response).to redirect_to(admin_root_path)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
