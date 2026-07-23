# frozen_string_literal: true

# == Schema Information
#
# Table name: partners
#
#  id                      :bigint           not null, primary key
#  accessibility_info      :text
#  accessibility_info_html :string
#  admin_email             :string
#  admin_name              :string
#  booking_info            :text
#  calendar_email          :string
#  calendar_name           :string
#  calendar_phone          :string
#  can_be_assigned_events  :boolean          default(FALSE), not null
#  description             :text
#  description_html        :string
#  facebook_link           :string
#  hidden                  :boolean          default(FALSE), not null
#  hidden_reason           :text
#  hidden_reason_html      :string
#  image                   :string
#  instagram_handle        :string
#  is_a_place              :boolean          default(FALSE), not null
#  name                    :string           not null
#  opening_times           :jsonb
#  partner_email           :string
#  partner_name            :string
#  partner_phone           :string
#  public_email            :string
#  public_name             :string
#  public_phone            :string
#  slug                    :string
#  summary                 :string
#  summary_html            :string
#  twitter_handle          :string
#  url                     :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  address_id              :bigint
#  hidden_blame_id         :integer
#
# Indexes
#
#  index_partners_hidden         (hidden)
#  index_partners_lower_name_    (lower((name)::text)) UNIQUE
#  index_partners_on_address_id  (address_id)
#  index_partners_on_slug        (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#
require "rails_helper"

RSpec.describe Partner, type: :model do
  describe "associations" do
    it { is_expected.to have_and_belong_to_many(:users) }
    it { is_expected.to have_many(:calendars).dependent(:destroy) }
    it { is_expected.to have_many(:events) }
    it { is_expected.to belong_to(:address).optional }
    it { is_expected.to have_many(:partner_tags).dependent(:destroy) }
    it { is_expected.to have_many(:tags).through(:partner_tags) }
    it { is_expected.to have_many(:categories).through(:partner_tags) }
    it { is_expected.to have_many(:facilities).through(:partner_tags) }
    it { is_expected.to have_many(:partnerships).through(:partner_tags) }
    it { is_expected.to have_many(:service_areas).dependent(:destroy) }
    it { is_expected.to have_many(:article_partners).dependent(:destroy) }
    it { is_expected.to have_many(:articles).through(:article_partners) }
  end

  describe "validations" do
    # shoulda-matchers needs an existing record for uniqueness validation
    subject { create(:partner) }

    describe "name" do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_uniqueness_of(:name).case_insensitive }

      it "requires minimum length of 5 characters" do
        partner = build(:partner, name: "1234")
        expect(partner).not_to be_valid
        expect(partner.errors[:name]).to include("must be at least 5 characters long")
      end
    end

    describe "summary and description" do
      let(:partner) { build(:partner) }

      it "allows no summary or description" do
        partner.summary = ""
        partner.description = ""
        expect(partner).to be_valid
      end

      it "allows summary without description" do
        partner.summary = "This is a test summary"
        partner.description = ""
        expect(partner).to be_valid
      end

      it "does not allow description without summary" do
        partner.summary = ""
        partner.description = "This is a description"
        expect(partner).not_to be_valid
        expect(partner.errors[:summary]).to include("cannot have a description without a summary")
      end

      it "allows both summary and description" do
        partner.summary = "This is a test summary"
        partner.description = "This is a description"
        expect(partner).to be_valid
      end

      it "limits summary to 200 characters" do
        partner.summary = "a" * 201
        expect(partner).not_to be_valid
        expect(partner.errors[:summary]).to be_present
      end
    end

    describe "url" do
      let(:partner) { build(:partner) }

      it "accepts valid URLs" do
        partner.url = "https://good-domain.com"
        partner.valid?
        expect(partner.errors[:url]).to be_empty
      end

      it "rejects invalid URLs" do
        partner.url = "htp://bad-domain.co"
        expect(partner).not_to be_valid
        expect(partner.errors[:url]).to include("is invalid")
      end

      it "allows blank URL" do
        partner.url = ""
        partner.valid?
        expect(partner.errors[:url]).to be_empty
      end
    end

    describe "twitter_handle" do
      let(:partner) { build(:partner) }

      it "accepts valid handle with @" do
        partner.twitter_handle = "@asdf"
        partner.valid?
        expect(partner.errors[:twitter_handle]).to be_empty
      end

      it "accepts valid handle without @" do
        partner.twitter_handle = "asdf"
        partner.valid?
        expect(partner.errors[:twitter_handle]).to be_empty
      end

      it "rejects full URL" do
        partner.twitter_handle = "https://twitter.com/asdf"
        expect(partner).not_to be_valid
        expect(partner.errors[:twitter_handle]).to be_present
      end

      it "rejects invalid characters" do
        partner.twitter_handle = "asd£$%dsa"
        expect(partner).not_to be_valid
        expect(partner.errors[:twitter_handle]).to be_present
      end
    end

    describe "facebook_link" do
      let(:partner) { build(:partner) }

      it "accepts valid page name" do
        partner.facebook_link = "GroupName"
        partner.valid?
        expect(partner.errors[:facebook_link]).to be_empty
      end

      it "rejects full URL" do
        partner.facebook_link = "https://facebook.com/group-name"
        expect(partner).not_to be_valid
        expect(partner.errors[:facebook_link]).to be_present
      end

      it "rejects hyphenated names" do
        partner.facebook_link = "Group-Name"
        expect(partner).not_to be_valid
        expect(partner.errors[:facebook_link]).to be_present
      end
    end

    describe "address or service area requirement" do
      let(:partner) { create(:partner) }

      it "requires at least address or service area" do
        partner.service_areas.destroy_all
        partner.address = nil
        expect(partner).not_to be_valid
        expect(partner.errors[:base]).to include("Partners must have at least one of service area or address")
      end
    end
  end

  describe "service_areas nested attributes" do
    let(:ward) { create(:riverside_ward) }

    it "rejects rows with a blank neighbourhood_id" do
      partner = build(:partner, service_areas_attributes: [
                        { neighbourhood_id: ward.id },
                        { neighbourhood_id: "" }
                      ])
      expect(partner.service_areas.size).to eq(1)
      expect(partner).to be_valid
    end

    # Regression test for issue #3356: an untouched "New Service Area" picker row
    # submits a blank neighbourhood_id, which used to build an invalid ServiceArea
    # and also fail check_neighbourhood_access for non-root admins
    it "lets a neighbourhood admin create a partner despite a leftover blank row" do
      admin = create(:neighbourhood_admin, neighbourhood: ward)
      partner = build(:partner, address: nil, accessed_by_user: admin,
                                service_areas_attributes: [
                                  { neighbourhood_id: ward.id },
                                  { neighbourhood_id: "" }
                                ])
      expect(partner).to be_valid
    end

    it "still removes existing service areas via _destroy" do
      partner = create(:mobile_partner, service_area_wards: [ward])
      sa = partner.service_areas.reload.first
      partner.update!(service_areas_attributes: [
                        { id: sa.id, neighbourhood_id: ward.id, _destroy: "1" }
                      ])
      expect(partner.reload.service_areas).to be_empty
    end
  end

  describe "factories" do
    it "creates a valid partner" do
      partner = build(:partner)
      expect(partner).to be_valid
    end

    it "creates a riverside partner" do
      partner = create(:riverside_partner)
      expect(partner.name).to eq("Riverside Community Hub")
      expect(partner.address).to be_present
    end

    it "creates a mobile partner with service areas" do
      ward = create(:riverside_ward)
      partner = create(:mobile_partner, service_area_wards: [ward])
      expect(partner.service_areas.count).to eq(1)
    end
  end

  describe "tag associations" do
    let(:partner) { create(:partner) }

    it "can have Category tags" do
      category = create(:category_tag)
      partner.tags << category
      partner.save
      expect(partner.categories.count).to eq(1)
    end

    it "can have Facility tags" do
      facility = create(:facility_tag)
      partner.tags << facility
      partner.save
      expect(partner.facilities.count).to eq(1)
    end

    it "can have Partnership tags" do
      partnership = create(:partnership_tag)
      partner.tags << partnership
      partner.save
      expect(partner.partnerships.count).to eq(1)
    end

    it "limits Category tags to MAX_CATEGORIES" do
      (Partner::MAX_CATEGORIES + 1).times { |n| partner.categories << create(:category_tag, name: "Category #{n}") }
      partner.save
      expect(partner.errors[:categories]).to include("Partners can have a maximum of #{Partner::MAX_CATEGORIES} Category tags")
    end

    it "allows up to MAX_CATEGORIES Category tags" do
      Partner::MAX_CATEGORIES.times { |n| partner.categories << create(:category_tag, name: "Category #{n}") }
      partner.save
      expect(partner).to be_valid
    end
  end

  describe "hiding partners" do
    let(:partner) { build(:partner) }

    it "cannot be hidden without a reason" do
      partner.hidden = true
      partner.hidden_blame_id = 1
      expect(partner).not_to be_valid
    end

    it "cannot be hidden without recording who hid it" do
      partner.hidden = true
      partner.hidden_reason = "Something wrong"
      expect(partner).not_to be_valid
    end

    it "can be hidden with reason and blame_id" do
      partner.hidden = true
      partner.hidden_reason = "Something wrong"
      partner.hidden_blame_id = 1
      expect(partner).to be_valid
    end
  end

  describe "user role management" do
    let(:user) { create(:user) }
    let(:partner) { create(:partner, accessed_by_user: user) }

    it "makes user a partner_admin when assigned" do
      user.partners << partner
      user.save
      expect(user).to be_partner_admin
    end
  end

  describe "address changes" do
    let(:user) { create(:root_user) }
    let(:partner) { create(:partner, accessed_by_user: user) }

    it "can update postcode" do
      new_postcode = "ZZAD 1HC" # Hillcrest
      partner.update!(
        address_attributes: {
          id: partner.address.id,
          street_address: partner.address.street_address,
          postcode: new_postcode
        }
      )
      partner.reload
      expect(partner.address.postcode).to eq(new_postcode)
    end
  end

  describe "opening times" do
    it "handles badly formatted opening times" do
      partner = build(:partner)
      partner.opening_times = "{{ $data.openingHoursSpecifications }}"
      expect(partner.human_readable_opening_times).to be_empty
    end

    it "defaults to empty array" do
      partner = described_class.new
      expect(partner.opening_times_data).to eq("[]")
    end

    it "accepts valid JSON" do
      opening_times = [
        { opens: "09:00", closes: "17:00" },
        { opens: "09:00", closes: "17:00" }
      ].to_json

      partner = described_class.new(opening_times: opening_times)
      found = JSON.parse(partner.opening_times_data)
      expect(found.length).to eq(2)
    end

    describe "validation" do
      def spec(day, opens, closes)
        { dayOfWeek: "http://schema.org/#{day}", opens: opens, closes: closes }
      end

      it "is valid with non-overlapping times across different days" do
        partner = build(:partner, opening_times: [
          spec("Monday", "09:00", "17:00"),
          spec("Tuesday", "10:00", "20:00")
        ].to_json)

        expect(partner).to be_valid
      end

      it "is valid with non-overlapping times on the same day" do
        partner = build(:partner, opening_times: [
          spec("Monday", "09:00", "12:00"),
          spec("Monday", "13:00", "17:00")
        ].to_json)

        expect(partner).to be_valid
      end

      it "is invalid when a closing time is before its opening time" do
        partner = build(:partner, opening_times: [
          spec("Monday", "17:00", "09:00")
        ].to_json)

        expect(partner).not_to be_valid
        expect(partner.errors[:opening_times])
          .to include(I18n.t("activerecord.errors.models.partner.attributes.opening_times.end_before_start"))
      end

      it "is invalid when a closing time equals its opening time" do
        partner = build(:partner, opening_times: [
          spec("Monday", "09:00", "09:00")
        ].to_json)

        expect(partner).not_to be_valid
        expect(partner.errors[:opening_times])
          .to include(I18n.t("activerecord.errors.models.partner.attributes.opening_times.end_before_start"))
      end

      it "is invalid when two ranges overlap on the same day" do
        partner = build(:partner, opening_times: [
          spec("Monday", "09:00", "13:00"),
          spec("Monday", "12:00", "17:00")
        ].to_json)

        expect(partner).not_to be_valid
        expect(partner.errors[:opening_times])
          .to include(I18n.t("activerecord.errors.models.partner.attributes.opening_times.overlapping"))
      end

      it "allows identical times on different days without flagging overlap" do
        partner = build(:partner, opening_times: [
          spec("Monday", "09:00", "17:00"),
          spec("Tuesday", "09:00", "17:00")
        ].to_json)

        expect(partner).to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".visible" do
      it "excludes hidden partners" do
        visible = create(:partner)
        hidden = create(:partner, hidden: true, hidden_reason: "Test", hidden_blame_id: 1)

        expect(described_class.visible).to include(visible)
        expect(described_class.visible).not_to include(hidden)
      end
    end
  end

  describe "#can_clear_address?" do
    let(:ward) { create(:riverside_ward) }

    it "returns false when partner has no address" do
      partner = build(:partner, address: nil)
      partner.service_areas.build(neighbourhood: ward)
      expect(partner.can_clear_address?).to be false
    end

    it "returns false when partner has no service areas" do
      partner = build(:partner)
      expect(partner.can_clear_address?).to be false
    end

    it "returns true for root user with address and service areas" do
      root = create(:root_user)
      partner = build(:partner)
      partner.service_areas.build(neighbourhood: ward)
      expect(partner.can_clear_address?(root)).to be true
    end

    it "returns true for partner admin" do
      citizen = create(:user)
      partner = create(:partner)
      partner.service_areas.create(neighbourhood: ward)
      citizen.partners << partner
      expect(partner.can_clear_address?(citizen)).to be true
    end
  end

  describe "#neighbourhood_name_for_site" do
    let(:partner) { create(:riverside_partner) }

    it "returns ward name at ward level" do
      expect(partner.neighbourhood_name_for_site("ward")).to eq("Riverside")
    end
  end
end
