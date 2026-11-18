# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin import runs", type: :request do
  let(:calendar) { create(:calendar, name: "Folk club feed") }
  let!(:failed) { calendar.import_runs.create!(started_at: 2.minutes.ago).tap { it.finish!(outcome: "bad_source", error: "This URL returned a 404") } }
  let!(:imported) { calendar.import_runs.create!(started_at: 1.hour.ago).tap { it.finish!(outcome: "imported", events_added: 3) } }

  it "turns away a user who isn't root" do
    sign_in create(:citizen_user)
    get admin_import_run_url(imported, host: admin_host)
    expect(response).to redirect_to(admin_root_path)
  end

  context "as a root user" do
    before { sign_in create(:root_user) }

    def rows(**params)
      get admin_import_runs_url(host: admin_host, format: :json, **params)
      response.parsed_body["data"]
    end

    it "gives the runs newest first, a failed run with its error as a detail line and a link to its page" do
      first, second = rows(order: { "0" => { column: "0", dir: "desc" } }, columns: { "0" => { data: "started_at" } })

      expect(first["DT_RowDetail"]).to include("This URL returned a 404")
      expect(first["DT_RowClass"]).to include("bg-red-50")
      expect(first["started_at"]).to include(admin_import_run_path(failed), "##{failed.id}")
      expect(second["DT_RowDetail"]).to be_nil
      expect(second["events_added"]).to include("3")
    end

    it "filters by an outcome, with failed covering errors, unreadable sources and interrupted runs" do
      expect(rows(filter: { outcome: "failed" }).size).to eq(1)
      expect(rows(filter: { outcome: "imported" }).size).to eq(1)
    end

    it "shows a run's page" do
      get admin_import_run_url(failed, host: admin_host)

      expect(response.body).to include("Import run ##{failed.id}", "Folk club feed", "This URL returned a 404")
    end
  end
end
