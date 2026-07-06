# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::PartnershipBroadcasts", type: :request do
  include ActiveJob::TestHelper

  let(:partnership) { create(:partnership) }
  let(:partner) { create(:partner, tags: [partnership]) }

  let!(:opted_in) do
    create(:user).tap do |user|
      user.partners << partner
      EmailSubscription.set(user, :partnership_updates, true, source: :profile_page)
    end
  end
  let!(:not_opted) { create(:user).tap { |user| user.partners << partner } }

  let(:valid_params) { { partnership_broadcast: { subject: "News", body: "Big update" } } }

  context "as a partnership admin" do
    let(:sender) { create(:user).tap { |u| u.tags << partnership } }

    before { sign_in sender }

    it "shows the compose form with the recipient preview" do
      get new_admin_partnership_broadcast_url(partnership, host: admin_host)

      expect(response).to be_successful
      # 1 eligible person, 1 partner, 1 excluded
      expect(response.body).to include("1") # counts rendered
      expect(response.body).to include(CGI.escapeHTML(
                                         I18n.t("admin.partnership_broadcasts.preview.excluded.one", count: 1)
                                       ))
    end

    it "renders the confirm step without saving or sending" do
      expect { post admin_partnership_broadcasts_url(partnership, host: admin_host), params: valid_params }
        .not_to change(PartnershipBroadcast, :count)

      expect(enqueued_jobs.select { |j| j["job_class"] == "PartnershipBroadcastDeliveryJob" }).to be_empty
      expect(response.body).to include(I18n.t("admin.partnership_broadcasts.confirm.title"))
    end

    it "saves the log and enqueues one job per opted-in recipient on confirm" do
      expect do
        post admin_partnership_broadcasts_url(partnership, host: admin_host),
             params: valid_params.merge(confirmed: "true")
      end.to change(PartnershipBroadcast, :count).by(1)

      broadcast = PartnershipBroadcast.last
      expect(broadcast.sender).to eq sender
      expect(broadcast.recipient_count).to eq 1
      expect(broadcast.excluded_count).to eq 1

      jobs = enqueued_jobs.select { |j| j["job_class"] == "PartnershipBroadcastDeliveryJob" }
      expect(jobs.size).to eq 1
      expect(jobs.first["arguments"].first["_aj_globalid"]).to eq opted_in.to_global_id.to_s
    end

    it "enforces the daily cap" do
      create(:partnership_broadcast, partnership: partnership, sender: sender)

      post admin_partnership_broadcasts_url(partnership, host: admin_host),
           params: valid_params.merge(confirmed: "true")

      expect(response).to have_http_status(:unprocessable_content)
      expect(PartnershipBroadcast.count).to eq 1
    end

    it "lists past broadcasts" do
      create(:partnership_broadcast, partnership: partnership, sender: sender, subject: "Past update")

      get admin_partnership_broadcasts_url(partnership, host: admin_host)

      expect(response).to be_successful
      expect(response.body).to include("Past update")
    end
  end

  context "as an admin of a different partnership" do
    before { sign_in(create(:user).tap { |u| u.tags << create(:partnership) }) }

    it "is denied" do
      post admin_partnership_broadcasts_url(partnership, host: admin_host),
           params: valid_params.merge(confirmed: "true")

      expect(response).to redirect_to(admin_root_path)
      expect(PartnershipBroadcast.count).to eq 0
    end
  end
end
