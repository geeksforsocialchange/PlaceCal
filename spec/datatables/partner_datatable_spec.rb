# frozen_string_literal: true

require "rails_helper"

# rubocop:disable Rails/SkipsModelValidations
RSpec.describe PartnerDatatable do
  # Create a view context with access to URL helpers using a real controller
  let(:view_context) do
    controller = Admin::PartnersController.new
    controller.request = ActionDispatch::TestRequest.create
    controller.view_context
  end
  let(:partners) { Partner.all }

  # Helper to create datatable with params
  def create_datatable(params = {})
    default_params = ActionController::Parameters.new({
      "draw" => "1",
      "start" => "0",
      "length" => "25",
      "search" => { "value" => "", "regex" => "false" },
      "columns" => {
        "0" => { "data" => "name", "searchable" => "true", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "1" => { "data" => "ward", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "2" => { "data" => "partnerships", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "3" => { "data" => "calendars", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "4" => { "data" => "admins", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "5" => { "data" => "categories", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "6" => { "data" => "updated_at", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "7" => { "data" => "actions", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } }
      },
      "order" => { "0" => { "column" => "0", "dir" => "asc" } }
    }.deep_merge(params))

    described_class.new(default_params, view_context: view_context, partners: partners)
  end

  describe "#view_columns" do
    it "defines all required columns" do
      datatable = create_datatable

      columns = datatable.view_columns
      expect(columns.keys).to contain_exactly(
        :name, :ward, :partnerships, :calendars, :admins, :categories, :updated_at, :actions
      )
    end

    it "makes name column searchable" do
      datatable = create_datatable

      expect(datatable.view_columns[:name][:searchable]).to be true
    end

    it "makes ward column not orderable" do
      datatable = create_datatable

      expect(datatable.view_columns[:ward][:orderable]).to be false
    end

    it "makes updated_at column orderable" do
      datatable = create_datatable

      expect(datatable.view_columns[:updated_at][:orderable]).to be true
    end
  end

  describe "#data" do
    let!(:partner) { create(:partner, name: "Test Partner") }

    it "returns array of hashes with all column keys" do
      datatable = create_datatable

      data = datatable.data
      expect(data).to be_an(Array)
      expect(data.first.keys).to contain_exactly(
        :name, :ward, :partnerships, :calendars, :admins, :categories, :updated_at, :actions
      )
    end

    context "name cell rendering" do
      it "includes partner name" do
        datatable = create_datatable

        name_html = datatable.data.first[:name]
        expect(name_html).to include("Test Partner")
      end

      it "includes link to edit page" do
        datatable = create_datatable

        name_html = datatable.data.first[:name]
        expect(name_html).to include("href=")
        expect(name_html).to include("/partners/")
        expect(name_html).to include("/edit")
      end

      it "includes partner ID" do
        datatable = create_datatable

        name_html = datatable.data.first[:name]
        expect(name_html).to include("##{partner.id}")
      end

      it "includes partner slug" do
        datatable = create_datatable

        name_html = datatable.data.first[:name]
        expect(name_html).to include("/#{partner.slug}")
      end
    end

    context "ward cell rendering" do
      let!(:ward) { create(:neighbourhood, name: "Riverside Ward", unit: "ward") }
      let!(:partner_with_ward) do
        address = create(:address, neighbourhood: ward)
        create(:partner, name: "Ward Partner", address: address)
      end

      it "shows ward name when partner has address with neighbourhood" do
        datatable = create_datatable

        ward_data = datatable.data.find { |d| d[:name].include?("Ward Partner") }
        expect(ward_data[:ward]).to include("Riverside")
      end

      it "shows dash when partner has no ward" do
        # Create a partner with only a service area (no neighbourhood)
        partner_no_ward = create(:partner, name: "No Ward Partner")
        # Remove the address to force no neighbourhood
        partner_no_ward.update_columns(address_id: nil)
        partner_no_ward.service_areas.destroy_all
        # Add a service area without neighbourhood to pass validation
        neighbourhood_without_ward = create(:neighbourhood, unit: "district")
        partner_no_ward.service_areas.create!(neighbourhood: neighbourhood_without_ward)

        datatable = create_datatable

        ward_data = datatable.data.find { |d| d[:name].include?("No Ward Partner") }
        # Service area neighbourhood is district, not ward, so it won't show a ward name
        expect(ward_data[:ward]).to include("—").or include(neighbourhood_without_ward.shortname)
      end

      it "truncates long ward names" do
        long_ward = create(:neighbourhood, name: "A Very Long Ward Name That Exceeds Twenty Characters", unit: "ward")
        address = create(:address, neighbourhood: long_ward)
        create(:partner, name: "Long Ward Partner", address: address)

        datatable = create_datatable

        ward_data = datatable.data.find { |d| d[:name].include?("Long Ward Partner") }
        # Code uses "..." (three dots) for truncation
        expect(ward_data[:ward]).to include("...")
      end
    end

    context "partnerships cell rendering" do
      let!(:partnership) { create(:partnership, name: "Community Partnership") }

      it "shows cross icon when no partnerships" do
        datatable = create_datatable

        partnerships_html = datatable.data.first[:partnerships]
        expect(partnerships_html).to include("svg")
        expect(partnerships_html).to include("text-gray-400")
      end

      it "shows partnership names when present" do
        partner.tags << partnership

        datatable = create_datatable

        partnerships_html = datatable.data.first[:partnerships]
        expect(partnerships_html).to include("Community Partnership")
      end

      it "includes filter data attributes" do
        partner.tags << partnership

        datatable = create_datatable

        partnerships_html = datatable.data.first[:partnerships]
        expect(partnerships_html).to include("data-filter-column=\"partnership\"")
        expect(partnerships_html).to include("data-filter-value=\"#{partnership.id}\"")
      end

      it "renders multiple partnerships as separate buttons" do
        partnership2 = create(:partnership, name: "Another Partnership")
        partner.tags << partnership
        partner.tags << partnership2

        datatable = create_datatable

        partnerships_html = datatable.data.first[:partnerships]
        # Code renders partnerships as buttons in a div with space-y-0.5 CSS spacing
        expect(partnerships_html).to include("Community Partnership")
        expect(partnerships_html).to include("Another Partnership")
        expect(partnerships_html).to include("space-y-0.5")
      end
    end

    context "calendars cell rendering" do
      it "shows cross icon when no calendars" do
        datatable = create_datatable

        calendars_html = datatable.data.first[:calendars]
        expect(calendars_html).to include("text-gray-400")
      end

      it "shows check icon when calendar connected" do
        create(:calendar, partner: partner)

        datatable = create_datatable

        calendars_html = datatable.data.first[:calendars]
        expect(calendars_html).to include("text-emerald-600")
      end

      it "shows error icon when calendar has errors" do
        calendar = create(:calendar, partner: partner)
        # Update calendar state after creation to ensure it's persisted
        calendar.update_column(:calendar_state, "error")

        datatable = create_datatable

        calendars_html = datatable.data.first[:calendars]
        expect(calendars_html).to include("text-red-600")
      end
    end

    context "admins cell rendering" do
      it "shows cross icon when no admins" do
        datatable = create_datatable

        admins_html = datatable.data.first[:admins]
        expect(admins_html).to include("text-gray-400")
      end

      it "shows check icon when has admins" do
        create(:partner_admin, partner: partner)

        datatable = create_datatable

        admins_html = datatable.data.first[:admins]
        expect(admins_html).to include("text-emerald-600")
      end

      it "includes count in title" do
        create(:partner_admin, partner: partner)
        create(:partner_admin, partner: partner)

        datatable = create_datatable

        admins_html = datatable.data.first[:admins]
        expect(admins_html).to include("2 admins")
      end
    end

    context "categories cell rendering" do
      let!(:category) { create(:category, name: "Health") }

      it "shows cross icon when no categories" do
        datatable = create_datatable

        categories_html = datatable.data.first[:categories]
        expect(categories_html).to include("text-gray-400")
      end

      it "shows check icon when has categories" do
        partner.tags << category

        datatable = create_datatable

        categories_html = datatable.data.first[:categories]
        expect(categories_html).to include("text-emerald-600")
      end
    end

    context "updated_at cell rendering" do
      it "shows 'Today' for updates today" do
        partner.update!(updated_at: Time.current)

        datatable = create_datatable

        updated_html = datatable.data.first[:updated_at]
        expect(updated_html).to include("Today")
      end

      it "shows 'Yesterday' for updates yesterday" do
        partner.update_column(:updated_at, 1.day.ago)

        datatable = create_datatable

        updated_html = datatable.data.first[:updated_at]
        expect(updated_html).to include("Yesterday")
      end

      it "shows 'X days ago' for recent updates" do
        partner.update_column(:updated_at, 3.days.ago)

        datatable = create_datatable

        updated_html = datatable.data.first[:updated_at]
        expect(updated_html).to include("3 days ago")
      end

      it "shows 'X weeks ago' for updates within a month" do
        partner.update_column(:updated_at, 2.weeks.ago)

        datatable = create_datatable

        updated_html = datatable.data.first[:updated_at]
        expect(updated_html).to include("2 weeks ago")
      end

      it "shows formatted date for older updates" do
        partner.update_column(:updated_at, 2.months.ago)

        datatable = create_datatable

        updated_html = datatable.data.first[:updated_at]
        expect(updated_html).to match(/\d{1,2} \w+ \d{4}/)
      end

      it "includes full datetime in title attribute" do
        datatable = create_datatable

        updated_html = datatable.data.first[:updated_at]
        expect(updated_html).to include("title=")
      end
    end

    context "actions cell rendering" do
      it "includes Edit link" do
        datatable = create_datatable

        actions_html = datatable.data.first[:actions]
        expect(actions_html).to include("Edit")
      end

      it "includes dropdown menu" do
        datatable = create_datatable

        actions_html = datatable.data.first[:actions]
        expect(actions_html).to include("data-controller=\"dropdown\"")
      end

      it "includes Calendars link in dropdown" do
        datatable = create_datatable

        actions_html = datatable.data.first[:actions]
        expect(actions_html).to include("Calendars")
      end

      it "includes Admin Users link in dropdown" do
        datatable = create_datatable

        actions_html = datatable.data.first[:actions]
        expect(actions_html).to include("Admin Users")
      end
    end
  end

  describe "#get_raw_records" do
    context "calendar_status filter" do
      let!(:partner_with_calendar) { create(:partner, name: "Has Calendar") }
      let!(:partner_without_calendar) { create(:partner, name: "No Calendar") }

      before { create(:calendar, partner: partner_with_calendar) }

      it "filters for connected calendars" do
        datatable = create_datatable("filter" => { "calendar_status" => "connected" })

        records = datatable.send(:get_raw_records)
        expect(records.to_a.map(&:name)).to include("Has Calendar")
        expect(records.to_a.map(&:name)).not_to include("No Calendar")
      end

      it "filters for no calendars" do
        datatable = create_datatable("filter" => { "calendar_status" => "none" })

        records = datatable.send(:get_raw_records)
        expect(records.to_a.map(&:name)).to include("No Calendar")
        expect(records.to_a.map(&:name)).not_to include("Has Calendar")
      end
    end

    context "has_admins filter" do
      let!(:partner_with_admin) { create(:partner, name: "Has Admin") }
      let!(:partner_without_admin) { create(:partner, name: "No Admin") }

      before { create(:partner_admin, partner: partner_with_admin) }

      it "filters for partners with admins" do
        datatable = create_datatable("filter" => { "has_admins" => "yes" })

        records = datatable.send(:get_raw_records)
        expect(records.to_a.map(&:name)).to include("Has Admin")
        expect(records.to_a.map(&:name)).not_to include("No Admin")
      end

      it "filters for partners without admins" do
        datatable = create_datatable("filter" => { "has_admins" => "no" })

        records = datatable.send(:get_raw_records)
        expect(records.to_a.map(&:name)).to include("No Admin")
        expect(records.to_a.map(&:name)).not_to include("Has Admin")
      end
    end

    context "district filter" do
      let!(:district) { create(:neighbourhood, name: "Test District", unit: "district") }
      let!(:ward1) { create(:neighbourhood, name: "Ward 1", unit: "ward", parent: district) }
      let!(:ward2) { create(:neighbourhood, name: "Ward 2", unit: "ward", parent: district) }
      let!(:other_ward) { create(:neighbourhood, name: "Other Ward", unit: "ward") }

      let!(:partner_in_ward1) do
        create(:partner, name: "In Ward 1", address: create(:address, neighbourhood: ward1))
      end
      let!(:partner_in_ward2) do
        create(:partner, name: "In Ward 2", address: create(:address, neighbourhood: ward2))
      end
      let!(:partner_outside) do
        create(:partner, name: "Outside", address: create(:address, neighbourhood: other_ward))
      end

      it "includes partners from all wards in the district" do
        datatable = create_datatable("filter" => { "district" => district.id.to_s })

        records = datatable.send(:get_raw_records)
        names = records.to_a.map(&:name)
        expect(names).to include("In Ward 1")
        expect(names).to include("In Ward 2")
        expect(names).not_to include("Outside")
      end
    end

    context "ward filter" do
      let!(:ward) { create(:neighbourhood, name: "Specific Ward", unit: "ward") }
      let!(:other_ward) { create(:neighbourhood, name: "Other Ward", unit: "ward") }

      let!(:partner_in_ward) do
        create(:partner, name: "In Specific Ward", address: create(:address, neighbourhood: ward))
      end
      let!(:partner_outside) do
        create(:partner, name: "Outside Ward", address: create(:address, neighbourhood: other_ward))
      end

      it "filters to specific ward only" do
        datatable = create_datatable("filter" => { "ward" => ward.id.to_s })

        records = datatable.send(:get_raw_records)
        names = records.to_a.map(&:name)
        expect(names).to include("In Specific Ward")
        expect(names).not_to include("Outside Ward")
      end
    end

    context "partnership filter" do
      let!(:partnership) { create(:partnership, name: "Test Partnership") }
      let!(:partner_in) { create(:partner, name: "In Partnership") }
      let!(:partner_out) { create(:partner, name: "Not In Partnership") }

      before { partner_in.tags << partnership }

      it "filters by partnership tag" do
        datatable = create_datatable("filter" => { "partnership" => partnership.id.to_s })

        records = datatable.send(:get_raw_records)
        names = records.to_a.map(&:name)
        expect(names).to include("In Partnership")
        expect(names).not_to include("Not In Partnership")
      end
    end

    context "category filter" do
      let!(:category) { create(:category, name: "Test Category") }
      let!(:partner_with_category) { create(:partner, name: "Has Category") }
      let!(:partner_without) { create(:partner, name: "No Category") }

      before { partner_with_category.tags << category }

      it "filters by category tag" do
        datatable = create_datatable("filter" => { "category" => category.id.to_s })

        records = datatable.send(:get_raw_records)
        names = records.to_a.map(&:name)
        expect(names).to include("Has Category")
        expect(names).not_to include("No Category")
      end
    end

    context "multiple filters" do
      let!(:partnership) { create(:partnership) }
      let!(:category) { create(:category) }
      let!(:partner_both) { create(:partner, name: "Both Items") }
      let!(:partner_one) { create(:partner, name: "First Partner") }
      let!(:partner_neither) { create(:partner, name: "Neither Partner") }

      before do
        create(:calendar, partner: partner_both)
        create(:partner_admin, partner: partner_both)
        partner_both.tags << partnership
        partner_both.tags << category

        partner_one.tags << partnership
      end

      it "combines all filters with AND logic" do
        datatable = create_datatable("filter" => {
                                       "calendar_status" => "connected",
                                       "has_admins" => "yes",
                                       "partnership" => partnership.id.to_s,
                                       "category" => category.id.to_s
                                     })

        records = datatable.send(:get_raw_records)
        names = records.to_a.map(&:name)
        expect(names).to eq(["Both Items"])
      end
    end
  end

  describe "#records_total_count" do
    before { 5.times { create(:partner) } }

    it "returns total count of all partners" do
      datatable = create_datatable

      expect(datatable.records_total_count).to eq(5)
    end

    it "returns same total count even when filters applied" do
      create(:calendar, partner: Partner.first)

      datatable = create_datatable("filter" => { "calendar_status" => "connected" })

      # Total should still be 5 even though only 1 matches the filter
      expect(datatable.records_total_count).to eq(5)
    end

    it "returns same total count even when search applied" do
      datatable = create_datatable("search" => { "value" => "Partner 1" })

      expect(datatable.records_total_count).to eq(5)
    end
  end

  describe "#records_filtered_count" do
    before do
      3.times { |i| create(:partner, name: "Match Partner #{i + 1}") }
      2.times { |i| create(:partner, name: "Other Partner #{i + 1}") }
    end

    it "returns count after search filter" do
      datatable = create_datatable("search" => { "value" => "Match" })

      expect(datatable.records_filtered_count).to eq(3)
    end

    it "returns count after custom filter" do
      match_partner = Partner.where("name LIKE ?", "Match%").first
      create(:calendar, partner: match_partner)

      datatable = create_datatable("filter" => { "calendar_status" => "connected" })

      expect(datatable.records_filtered_count).to eq(1)
    end

    it "returns count after both search and custom filter" do
      match_partner = Partner.where("name LIKE ?", "Match%").first
      create(:calendar, partner: match_partner)

      datatable = create_datatable(
        "search" => { "value" => "Match" },
        "filter" => { "calendar_status" => "connected" }
      )

      expect(datatable.records_filtered_count).to eq(1)
    end
  end
end
# rubocop:enable Rails/SkipsModelValidations
