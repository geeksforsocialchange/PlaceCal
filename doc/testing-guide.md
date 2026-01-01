# PlaceCal Testing Guide

A guide for writing and running tests in PlaceCal.

> **Migration Note:** The test suite was migrated from Minitest to RSpec + Cucumber. See [ADR-0009](adr/0009-test-suite-migration.md) for migration details and file mappings.

## Quick Reference

### Running Tests

```bash
# Fast unit tests (default, excludes browser tests)
bin/test --unit --no-lint

# System tests (browser-based, slower)
bin/test --system --no-lint

# Cucumber features (BDD acceptance tests)
bin/test --cucumber --no-lint

# All tests
bin/test --no-lint

# Run specific spec
bundle exec rspec spec/models/partner_spec.rb

# Run with verbose output
bundle exec rspec --format documentation
```

### Test Locations

| Type            | Location           | Purpose                      |
| --------------- | ------------------ | ---------------------------- |
| Model specs     | `spec/models/`     | Validations, scopes, methods |
| Policy specs    | `spec/policies/`   | Authorization rules          |
| Request specs   | `spec/requests/`   | HTTP responses, APIs         |
| Component specs | `spec/components/` | ViewComponent rendering      |
| Job specs       | `spec/jobs/`       | Background job logic         |
| Helper specs    | `spec/helpers/`    | View helper methods          |
| Mailer specs    | `spec/mailers/`    | Email delivery               |
| System specs    | `spec/system/`     | Browser-based UI tests       |
| Cucumber        | `features/`        | BDD acceptance tests         |

---

## Writing Tests

### 1. Model Specs

Test validations, associations, scopes, and methods.

```ruby
# spec/models/partner_spec.rb
RSpec.describe Partner, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:summary).is_at_most(200) }
  end

  describe 'associations' do
    it { should belong_to(:address).optional }
    it { should have_many(:calendars) }
    it { should have_many(:events).through(:calendars) }
  end

  describe 'scopes' do
    describe '.published' do
      it 'returns only published partners' do
        published = create(:riverside_community_hub, is_published: true)
        draft = create(:oldtown_library, is_published: false)

        expect(Partner.published).to include(published)
        expect(Partner.published).not_to include(draft)
      end
    end
  end

  describe '#full_address' do
    it 'returns formatted address' do
      partner = build(:riverside_community_hub)
      expect(partner.full_address).to include('Riverside')
    end
  end
end
```

**Tips:**

- Use `build` instead of `create` when you don't need persistence
- Use Normal Island factories for location-based tests
- Test edge cases (nil values, empty strings)

### 2. Policy Specs

Test authorization for each user role.

```ruby
# spec/policies/partner_policy_spec.rb
RSpec.describe PartnerPolicy, type: :policy do
  subject { described_class.new(user, partner) }

  let(:partner) { create(:riverside_community_hub) }

  context 'as a root user' do
    let(:user) { create(:root_user) }

    it { should permit_actions([:index, :show, :create, :update, :destroy]) }
  end

  context 'as a partner admin for this partner' do
    let(:user) { create(:partner_admin, partner: partner) }

    it { should permit_actions([:show, :update]) }
    it { should forbid_actions([:create, :destroy]) }
  end

  context 'as a partner admin for a different partner' do
    let(:other_partner) { create(:oldtown_library) }
    let(:user) { create(:partner_admin, partner: other_partner) }

    it { should forbid_actions([:show, :update, :destroy]) }
  end

  context 'as a citizen' do
    let(:user) { create(:user) }

    it { should permit_action(:show) }
    it { should forbid_actions([:create, :update, :destroy]) }
  end
end
```

### 3. Request Specs

Test HTTP responses and API contracts.

```ruby
# spec/requests/admin/partners_spec.rb
RSpec.describe 'Admin Partners', type: :request do
  let(:admin) { create(:root_user) }

  before do
    create_default_site
    sign_in admin
  end

  describe 'GET /admin/partners' do
    it 'returns success' do
      get admin_partners_path
      expect(response).to have_http_status(:success)
    end

    it 'lists all partners' do
      partner = create(:riverside_community_hub)
      get admin_partners_path
      expect(response.body).to include(partner.name)
    end
  end

  describe 'POST /admin/partners' do
    let(:valid_params) { { partner: { name: 'New Partner' } } }

    it 'creates a partner' do
      expect {
        post admin_partners_path, params: valid_params
      }.to change(Partner, :count).by(1)
    end

    it 'redirects to the partner' do
      post admin_partners_path, params: valid_params
      expect(response).to redirect_to(admin_partner_path(Partner.last))
    end
  end
end

# spec/requests/graphql/partners_spec.rb
RSpec.describe 'GraphQL Partners', type: :request do
  let(:query) do
    <<~GQL
      query {
        partnerConnection {
          edges {
            node { id name }
          }
        }
      }
    GQL
  end

  it 'returns partners' do
    partner = create(:riverside_community_hub)
    post '/api/v1/graphql', params: { query: query }

    json = JSON.parse(response.body)
    names = json.dig('data', 'partnerConnection', 'edges').map { |e| e.dig('node', 'name') }
    expect(names).to include(partner.name)
  end
end
```

### 4. Component Specs

Test ViewComponent rendering.

```ruby
# spec/components/partner_preview_component_spec.rb
RSpec.describe PartnerPreviewComponent, type: :component do
  let(:partner) { create(:riverside_community_hub) }

  it 'renders partner name' do
    render_inline(described_class.new(partner: partner))
    expect(page).to have_text(partner.name)
  end

  it 'renders partner summary' do
    render_inline(described_class.new(partner: partner))
    expect(page).to have_text(partner.summary)
  end

  context 'when partner has no image' do
    let(:partner) { create(:partner, image: nil) }

    it 'renders placeholder' do
      render_inline(described_class.new(partner: partner))
      expect(page).to have_css('.placeholder-image')
    end
  end
end
```

### 5. Job Specs

Test background jobs, use VCR for external APIs.

```ruby
# spec/jobs/calendar_importer/calendar_importer_spec.rb
RSpec.describe CalendarImporter::CalendarImporterJob, type: :job do
  let(:calendar) { create(:calendar, source: 'https://example.com/feed.ics') }

  describe 'enqueueing' do
    it 'enqueues the job' do
      expect {
        described_class.perform_later(calendar.id)
      }.to have_enqueued_job(described_class).with(calendar.id)
    end
  end

  describe 'execution' do
    it 'imports events from calendar feed', :vcr do
      VCR.use_cassette('calendar_import') do
        expect {
          described_class.perform_now(calendar.id)
        }.to change { calendar.events.count }
      end
    end
  end
end
```

### 6. System Specs

Browser-based tests for critical flows. Tag with `:slow`.

```ruby
# spec/system/admin/partners_spec.rb
RSpec.describe 'Admin Partners', :slow, type: :system do
  include_context 'admin login'

  let!(:partner) { create(:riverside_community_hub) }

  describe 'partner list' do
    it 'shows all partners' do
      click_link 'Partners'
      await_datatables
      expect(page).to have_content(partner.name)
    end
  end

  describe 'creating a partner' do
    it 'creates a new partner' do
      click_link 'Partners'
      await_datatables
      click_link 'Add New Partner'

      fill_in 'Name', with: 'New Community Centre'
      click_button 'Save and continue...'

      expect(page).to have_selector('.alert-success')
    end
  end

  describe 'select2 dropdowns' do
    let!(:partnership) { create(:partnership) }

    it 'allows selecting tags' do
      click_link 'Partners'
      await_datatables
      click_link partner.name

      partnerships_node = select2_node('partner_partnerships')
      select2 partnership.name, xpath: partnerships_node.path
      assert_select2_multiple [partnership.name], partnerships_node

      click_button 'Save Partner'
      expect(page).to have_selector('.alert-success')
    end
  end
end
```

**System spec helpers:**

- `include_context 'admin login'` - logs in as root user
- `await_datatables` - waits for DataTables to load
- `select2_node(class)` - finds Select2 container
- `select2 value, xpath:` - selects value in Select2
- `assert_select2_single` / `assert_select2_multiple` - verify selections

### 7. Cucumber Features

Business-readable acceptance tests.

```gherkin
# features/admin/partner_management.feature
@admin
Feature: Partner Management
  As an administrator
  I want to manage partners
  So that community organisations can share their events

  Background:
    Given I am logged in as a root user

  Scenario: Creating a new partner
    When I create a new partner with name "Community Hub"
    Then I should see a success message
    And I should see the partner "Community Hub" in the list

  Scenario: Editing a partner
    Given there is a partner called "Old Name"
    When I edit the partner "Old Name"
    And I update the partner summary to "New summary text"
    Then I should see a success message
    And the partner "Old Name" should have summary "New summary text"
```

**Step definitions** go in `features/step_definitions/`:

```ruby
# features/step_definitions/partner_steps.rb
Given('there is a partner called {string}') do |name|
  @partner = create(:partner, name: name)
end

When('I create a new partner with name {string}') do |name|
  click_link 'Partners'
  await_datatables
  click_link 'Add New Partner'
  fill_in 'Name', with: name
  click_button 'Save and continue...'
end
```

---

## Factory Reference

### Users

```ruby
create(:user)                                    # Citizen (basic user)
create(:root_user)                               # Full admin access
create(:partner_admin, partner: partner)         # Admin for specific partner
create(:neighbourhood_admin, neighbourhood: ward) # Admin for neighbourhood
create(:partnership_admin, partnership_tag: tag) # Admin for partnership
```

### Locations (Normal Island)

```ruby
# Hierarchy: Country → Region → County → District → Ward
create(:normal_island_country)
create(:northvale_region)          # or :southmere_region
create(:greater_millbrook_county)  # or :coastshire_county
create(:millbrook_district)        # or :ashdale_district, :seaview_district
create(:riverside_ward)            # or :oldtown_ward, :greenfield_ward, etc.

# Addresses (automatically linked to ward)
create(:riverside_address)
create(:oldtown_address)
create(:hillcrest_address)
```

### Partners

```ruby
create(:partner)                   # Generic partner (no address)
create(:riverside_community_hub)   # In Riverside ward
create(:oldtown_library)           # In Oldtown ward
create(:greenfield_youth_centre)   # In Greenfield ward
create(:harbourside_arts_centre)   # In Harbourside ward
create(:ashdale_sports_club)       # In Hillcrest ward
create(:coastline_wellness_centre) # In Cliffside ward

# Partner with service areas (mobile/outreach)
create(:mobile_partner, service_area_wards: [ward1, ward2])
```

### Sites

```ruby
create(:site)                      # Generic site
create(:site, slug: 'default-site') # Required for routing
```

### Events & Calendars

```ruby
create(:calendar, partner: partner)
create(:calendar, partner: partner, source: 'https://example.com/feed.ics')

create(:event, partner: partner)
create(:event, partner: partner, dtstart: 1.day.from_now)
```

### Tags

```ruby
create(:tag)         # Generic tag (Facility type)
create(:category)    # Category tag
create(:facility)    # Facility tag
create(:partnership) # Partnership tag

# Named tags
create(:health_wellbeing_tag)
create(:arts_culture_tag)
create(:wheelchair_accessible_tag)
create(:millbrook_together_tag)
```

### Other

```ruby
create(:article)
create(:article, partners: [partner1, partner2])

create(:collection)
create(:online_address)
create(:service_area, partner: partner, neighbourhood: ward)
```

---

## Support Files

| File                              | Purpose                      |
| --------------------------------- | ---------------------------- |
| `spec/rails_helper.rb`            | Main RSpec configuration     |
| `spec/support/capybara.rb`        | Browser/Selenium setup       |
| `spec/support/select2_helpers.rb` | Select2 dropdown helpers     |
| `spec/support/system_helpers.rb`  | System test utilities        |
| `spec/support/site_helpers.rb`    | `create_default_site` helper |
| `spec/support/graphql_helpers.rb` | GraphQL test utilities       |
| `spec/support/vcr.rb`             | HTTP recording config        |
| `spec/support/shared_examples/`   | Reusable test examples       |
| `spec/support/shared_contexts/`   | Reusable test setup          |

---

## Normal Island Quick Reference

```
NORMAL ISLAND (ZZ - user-assigned ISO 3166 code)
├── Northvale (Region)
│   └── Greater Millbrook (County)
│       ├── Millbrook (District)
│       │   ├── Riverside   → ZZMB 1RS → Riverside Community Hub
│       │   ├── Oldtown     → ZZMB 2OT → Oldtown Library
│       │   ├── Greenfield  → ZZMB 3GF → Greenfield Youth Centre
│       │   └── Harbourside → ZZMB 4HS → Harbourside Arts Centre
│       └── Ashdale (District)
│           ├── Hillcrest   → ZZAD 1HC → Ashdale Sports Club
│           └── Valleyview  → ZZAD 2VV
└── Southmere (Region)
    └── Coastshire (County)
        └── Seaview (District)
            ├── Cliffside   → ZZSV 1CL → Coastline Wellness Centre
            └── Beachfront  → ZZSV 2BF
```

See [lib/normal_island.rb](../lib/normal_island.rb) for full data definitions.
