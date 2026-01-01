# Test Suite Migration to RSpec + Cucumber with Normal Island Data

- Deciders: TBD
- Date: 2025-12-10
- Status: **Completed**

## Context and Problem Statement

The current PlaceCal test suite has several issues:

- 112 test files using Minitest (~11,500 lines, ~500 test methods)
- Test data uses UK-specific geography (Manchester, Hulme, Moss Side, real postcodes)
- Tests are coupled to real-world locations which can change
- No BDD/acceptance test layer exists
- Factories mix real places with test data, making tests brittle
- Test organization is inconsistent across layers

We need a modern, maintainable test suite that:

- Uses fictional test data to avoid coupling to real-world changes
- Provides clear separation between test types
- Includes executable business documentation via BDD
- Supports the goal of making PlaceCal deployable globally (issue #1478)

## Decision Drivers

- Need for consistent, reliable test data not tied to real UK geography
- Desire for better test readability and maintainability
- Requirement for business-readable acceptance tests
- Goal of preparing PlaceCal for global deployment
- Current test suite is difficult to maintain and extend

## Considered Options

1. Keep Minitest, just refactor test data to use fictional places
2. Migrate to RSpec only, keep existing test structure
3. Migrate to RSpec + Cucumber with complete fictional geography ("Normal Island")

## Decision Outcome

Chosen option 3: Full migration to RSpec + Cucumber with Normal Island data.

### Positive Consequences

- RSpec's expressive DSL improves test readability
- Shared examples reduce duplication
- Cucumber provides executable documentation for stakeholders
- Normal Island prevents coupling to real-world UK data changes
- Clear separation of test types with documented guidelines
- Better alignment with issue #1478 (global deployment readiness)
- Consistent test data between test suite and development seeds

### Negative Consequences

- Learning curve for team members unfamiliar with RSpec/Cucumber
- Migration effort required
- Temporary dual test suites during migration

---

## Implementation Phases

| Phase | Description                                        | Status      |
| ----- | -------------------------------------------------- | ----------- |
| 1     | Foundation Setup (gems, config, move legacy tests) | ✅ Complete |
| 2     | Normal Island Data & Factories                     | ✅ Complete |
| 3     | Model Specs                                        | ✅ Complete |
| 4     | Component Specs                                    | ✅ Complete |
| 5     | Policy Specs                                       | ✅ Complete |
| 6     | Request Specs                                      | ✅ Complete |
| 7     | Job Specs (Calendar Importer)                      | ✅ Complete |
| 8     | System Specs                                       | ✅ Complete |
| 9     | Cucumber Features                                  | ✅ Complete |
| 10    | Development Seeds & Cleanup                        | ✅ Complete |

### Final Test Counts

| Type                                   | Count |
| -------------------------------------- | ----- |
| RSpec examples (fast, default)         | 678   |
| RSpec examples (including slow/system) | 704   |
| Cucumber scenarios                     | 23    |
| Cucumber steps                         | 109   |

**Test Reliability**: RSpec suite verified with 5 consecutive passes using random seeds.

---

## Migration Map

### Directory Structure Changes

| Old Location | New Location | Notes                         |
| ------------ | ------------ | ----------------------------- |
| `test/`      | _(removed)_  | Legacy Minitest suite deleted |
| —            | `spec/`      | RSpec test root               |
| —            | `features/`  | Cucumber features             |

### Test File Migration

#### Models (`test/models/` → `spec/models/`)

| Legacy Test              | New Spec                 |
| ------------------------ | ------------------------ |
| `partner_test.rb`        | `partner_spec.rb`        |
| `event_test.rb`          | `event_spec.rb`          |
| `calendar_test.rb`       | `calendar_spec.rb`       |
| `user_test.rb`           | `user_spec.rb`           |
| `site_test.rb`           | `site_spec.rb`           |
| `address_test.rb`        | `address_spec.rb`        |
| `neighbourhood_test.rb`  | `neighbourhood_spec.rb`  |
| `tag_test.rb`            | `tag_spec.rb`            |
| `article_test.rb`        | `article_spec.rb`        |
| `collection_test.rb`     | `collection_spec.rb`     |
| `online_address_test.rb` | `online_address_spec.rb` |
| `calendar_state_test.rb` | `calendar_state_spec.rb` |

#### Policies (`test/policies/` → `spec/policies/`)

| Legacy Test               | New Spec                  |
| ------------------------- | ------------------------- |
| `partner_policy_test.rb`  | `partner_policy_spec.rb`  |
| `user_policy_test.rb`     | `user_policy_spec.rb`     |
| `article_policy_test.rb`  | `article_policy_spec.rb`  |
| `calendar_policy_test.rb` | `calendar_policy_spec.rb` |

#### Controllers/Integration → Request Specs

| Legacy Location             | New Location             |
| --------------------------- | ------------------------ |
| `test/controllers/admin/`   | `spec/requests/admin/`   |
| `test/controllers/public/`  | `spec/requests/public/`  |
| `test/integration/graphql/` | `spec/requests/graphql/` |

#### Components (`test/components/` → `spec/components/`)

| Legacy Test                         | New Spec                            |
| ----------------------------------- | ----------------------------------- |
| `address_component_test.rb`         | `address_component_spec.rb`         |
| `breadcrumb_component_test.rb`      | `breadcrumb_component_spec.rb`      |
| `partner_filter_component_test.rb`  | `partner_filter_component_spec.rb`  |
| `partner_preview_component_test.rb` | `partner_preview_component_spec.rb` |

#### Jobs (`test/jobs/` → `spec/jobs/`)

| Legacy Test                   | New Spec                      |
| ----------------------------- | ----------------------------- |
| `calendar_importer/*_test.rb` | `calendar_importer/*_spec.rb` |

#### Helpers (`test/helpers/` → `spec/helpers/`)

| Legacy Test                | New Spec                   |
| -------------------------- | -------------------------- |
| `mailer_helper_test.rb`    | `mailer_helper_spec.rb`    |
| `articles_helper_test.rb`  | `articles_helper_spec.rb`  |
| `partners_helper_test.rb`  | `partners_helper_spec.rb`  |
| `users_helper_test.rb`     | `users_helper_spec.rb`     |
| `calendars_helper_test.rb` | `calendars_helper_spec.rb` |

#### Mailers (`test/mailers/` → `spec/mailers/`)

| Legacy Test                             | New Spec                                |
| --------------------------------------- | --------------------------------------- |
| `join_mailer_test.rb`                   | `join_mailer_spec.rb`                   |
| `devise_user_invitation_mailer_test.rb` | `devise_user_invitation_mailer_spec.rb` |

#### System Tests (`test/system/` → `spec/system/`)

| Legacy Test                   | New Spec                        |
| ----------------------------- | ------------------------------- |
| `admin/partner_test.rb`       | `admin/partners_spec.rb`        |
| `admin/calendar_test.rb`      | `admin/calendars_spec.rb`       |
| `admin/article_test.rb`       | `admin/articles_spec.rb`        |
| `admin/user_test.rb`          | `admin/users_spec.rb`           |
| `admin/site_test.rb`          | `admin/sites_spec.rb`           |
| `admin/tag_test.rb`           | `admin/tags_spec.rb`            |
| `admin/neighbourhood_test.rb` | `admin/neighbourhoods_spec.rb`  |
| `create_admin_users_test.rb`  | `user_invitation_spec.rb`       |
| `graphql/graphql_test.rb`     | `graphql/api_spec.rb`           |
| `collections_test.rb`         | _(skipped - was commented out)_ |

#### Cucumber Features (`features/`)

| Feature File                     | Scenarios | Description                          |
| -------------------------------- | --------- | ------------------------------------ |
| `admin/sites.feature`            | 4         | Site management (list, create, view) |
| `admin/articles.feature`         | 5         | Article management and associations  |
| `admin/tags.feature`             | 5         | Tag CRUD and partner assignment      |
| `admin/calendars.feature`        | 2         | Calendar viewing and listing         |
| `admin/users.feature`            | 2         | User management access               |
| `admin/partners.feature`         | 3         | Partner CRUD operations              |
| `public/news.feature`            | 4         | News browsing and article display    |
| `public/site_browsing.feature`   | 5         | Site homepage, events, partners      |
| `public/browse_events.feature`   | 3         | Event listing and details            |
| `public/browse_partners.feature` | 2         | Partner listing                      |
| `authentication.feature`         | 3         | Login/logout flows                   |

#### Step Definitions (`features/step_definitions/`)

| File                      | Purpose                                  |
| ------------------------- | ---------------------------------------- |
| `authentication_steps.rb` | Login/logout, user creation              |
| `navigation_steps.rb`     | Page visits, clicks, content assertions  |
| `partner_steps.rb`        | Partner creation and management          |
| `event_steps.rb`          | Event creation with dates                |
| `calendar_steps.rb`       | Calendar management                      |
| `article_steps.rb`        | Article creation with site-aware linking |
| `site_steps.rb`           | Site management, subdomain navigation    |
| `tag_steps.rb`            | Tag creation and partner tagging         |

---

## Normal Island Geography

Fictional geography hierarchy using "ZZ" as country code (a user-assigned ISO 3166 code):

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NORMAL ISLAND (Country)                           │
│                              Code: ZZ                                       │
├─────────────────────────────────┬───────────────────────────────────────────┤
│           NORTHVALE             │              SOUTHMERE                    │
│            (Region)             │               (Region)                    │
├─────────────────────────────────┼───────────────────────────────────────────┤
│      GREATER MILLBROOK          │            COASTSHIRE                     │
│          (County)               │              (County)                     │
├────────────────┬────────────────┼───────────────────────────────────────────┤
│   MILLBROOK    │    ASHDALE     │              SEAVIEW                      │
│   (District)   │   (District)   │             (District)                    │
├────────────────┼────────────────┼─────────────────────┬─────────────────────┤
│  ┌──────────┐  │  ┌──────────┐  │    ┌──────────┐     │    ┌──────────┐    │
│  │Riverside │  │  │Hillcrest │  │    │Cliffside │     │    │Beachfront│    │
│  │  (Ward)  │  │  │  (Ward)  │  │    │  (Ward)  │     │    │  (Ward)  │    │
│  │ ZZMB 1RS │  │  │ ZZAD 1HC │  │    │ ZZSV 1CS │     │    │ ZZSV 2BF │    │
│  └──────────┘  │  └──────────┘  │    └──────────┘     │    └──────────┘    │
│  ┌──────────┐  │  ┌──────────┐  │                     │                    │
│  │ Oldtown  │  │  │Valleyview│  │                     │                    │
│  │  (Ward)  │  │  │  (Ward)  │  │                     │                    │
│  │ ZZMB 2OT │  │  │ ZZAD 2VV │  │                     │                    │
│  └──────────┘  │  └──────────┘  │                     │                    │
│  ┌──────────┐  │                │                     │                    │
│  │Greenfield│  │                │                     │                    │
│  │  (Ward)  │  │                │                     │                    │
│  │ ZZMB 3GF │  │                │                     │                    │
│  └──────────┘  │                │                     │                    │
│  ┌──────────┐  │                │                     │                    │
│  │Harbourside│ │                │                     │                    │
│  │  (Ward)  │  │                │                     │                    │
│  │ ZZMB 4HS │  │                │                     │                    │
│  └──────────┘  │                │                     │                    │
└────────────────┴────────────────┴─────────────────────┴─────────────────────┘
```

### Postcode Format

Normal Island postcodes follow the pattern: `ZZ[District] [Ward][Number]` (ZZ is a user-assigned ISO 3166 code)

| Ward        | District  | Postcode   |
| ----------- | --------- | ---------- |
| Riverside   | Millbrook | `ZZMB 1RS` |
| Oldtown     | Millbrook | `ZZMB 2OT` |
| Greenfield  | Millbrook | `ZZMB 3GF` |
| Harbourside | Millbrook | `ZZMB 4HS` |
| Hillcrest   | Ashdale   | `ZZAD 1HC` |
| Valleyview  | Ashdale   | `ZZAD 2VV` |
| Cliffside   | Seaview   | `ZZSV 1CS` |
| Beachfront  | Seaview   | `ZZSV 2BF` |

### Partners

| Partner                   | Ward        | Factory                      |
| ------------------------- | ----------- | ---------------------------- |
| Riverside Community Hub   | Riverside   | `:riverside_community_hub`   |
| Oldtown Library           | Oldtown     | `:oldtown_library`           |
| Greenfield Youth Centre   | Greenfield  | `:greenfield_youth_centre`   |
| Harbourside Arts Centre   | Harbourside | `:harbourside_arts_centre`   |
| Ashdale Sports Club       | Hillcrest   | `:ashdale_sports_club`       |
| Coastline Wellness Centre | Cliffside   | `:coastline_wellness_centre` |

### Sites

| Site                         | Slug           | Coverage             |
| ---------------------------- | -------------- | -------------------- |
| Normal Island Central        | `default-site` | All of Normal Island |
| Millbrook Community Calendar | `millbrook`    | Millbrook District   |
| Ashdale Connect              | `ashdale`      | Ashdale District     |
| Coastshire Events            | `coastshire`   | Coastshire County    |

---

## Configuration Changes

### Files Modified

| File                      | Change                                                     |
| ------------------------- | ---------------------------------------------------------- |
| `Gemfile`                 | Added rspec-rails, cucumber-rails, factory_bot_rails, etc. |
| `.rspec`                  | RSpec configuration                                        |
| `spec/spec_helper.rb`     | RSpec base configuration                                   |
| `spec/rails_helper.rb`    | Rails-specific RSpec configuration                         |
| `config/cucumber.yml`     | Cucumber profiles                                          |
| `features/support/env.rb` | Cucumber environment setup                                 |
| `bin/test`                | Updated to run RSpec/Cucumber instead of Minitest          |

### Running Tests

```bash
# Fast unit tests (default, excludes slow/system)
bin/test --unit --no-lint

# System tests only (browser-based)
bin/test --system --no-lint

# Cucumber features only
bin/test --cucumber --no-lint

# All tests
bin/test --no-lint

# Direct commands
bundle exec rspec                          # Fast specs
RUN_SLOW_TESTS=true bundle exec rspec      # All specs including system
bundle exec cucumber                        # Cucumber features
```

### CI Configuration

GitHub Actions workflow (`.github/workflows/test-and-deploy.yml`) includes:

| Step              | Configuration                                  |
| ----------------- | ---------------------------------------------- |
| Chrome install    | `browser-actions/setup-chrome@latest` (stable) |
| RSpec command     | `RUN_SLOW_TESTS=true bundle exec rspec`        |
| Cucumber command  | `bundle exec cucumber --tags "not @wip"`       |
| Screenshot upload | `tmp/capybara/` on test failure                |
| Linting           | RuboCop and Prettier                           |

**Flaky Test Fixes Applied:**

- Dynamic ActionMailer port configuration in `spec/support/capybara.rb`
- Capybara session reset between system tests (before and after hooks)
- Unique email generation in invitation tests

---

## Testing Guidelines

| Test Type        | Use For                                     | Speed  |
| ---------------- | ------------------------------------------- | ------ |
| Model Spec       | Validations, scopes, instance/class methods | Fast   |
| Policy Spec      | Authorization rules per role                | Fast   |
| Component Spec   | ViewComponent rendering, slots, variants    | Fast   |
| Request Spec     | HTTP responses, API contracts, redirects    | Medium |
| Job Spec         | Background job logic, external API calls    | Medium |
| System Spec      | Critical UI flows, JavaScript interactions  | Slow   |
| Cucumber Feature | Business scenarios, acceptance criteria     | Slow   |

### Rules

1. **Model specs**: Test all validations, scopes, and methods. Use `build` over `create` when possible.
2. **Policy specs**: Test all CRUD actions for all roles. Use shared examples.
3. **Component specs**: Test rendering, slots, and edge cases. Use `render_inline`.
4. **Request specs**: Test response codes and JSON structure. Don't test UI.
5. **System specs**: Only for critical user journeys. One flow per test. Tag with `:slow`.
6. **Cucumber**: Business-readable. One scenario per acceptance criterion.

---

## References

- [Testing Guide](../testing-guide.md) - Detailed guide for writing new tests
- [Normal Island data](../../lib/normal_island.rb) - Source of truth for fictional geography
- [RSpec documentation](https://rspec.info/documentation/)
- [Cucumber documentation](https://cucumber.io/docs/cucumber/)
