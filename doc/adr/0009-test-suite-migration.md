# Test Suite Migration to RSpec + Cucumber with Normal Island Data

- Deciders: TBD
- Date: 2025-12-10

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

## Normal Island Geography

Fictional geography hierarchy using "NO" as country code:

```
Country: Normal Island (NO)
├── Region: Northvale
│   └── County: Greater Millbrook
│       ├── District: Millbrook
│       │   ├── Ward: Riverside
│       │   ├── Ward: Oldtown
│       │   ├── Ward: Greenfield
│       │   └── Ward: Harbourside
│       └── District: Ashdale
│           ├── Ward: Hillcrest
│           └── Ward: Valleyview
└── Region: Southmere
    └── County: Coastshire
        └── District: Seaview
            ├── Ward: Cliffside
            └── Ward: Beachfront
```

Postcode format: `NO[District] [Ward][Number]` (e.g., `NOMB 1RS` for Riverside)

## Testing Guidelines

| Test Type | Use For | Speed |
|-----------|---------|-------|
| Model Spec | Validations, scopes, instance/class methods | Fast |
| Policy Spec | Authorization rules per role | Fast |
| Component Spec | ViewComponent rendering, slots, variants | Fast |
| Request Spec | HTTP responses, API contracts, redirects | Medium |
| Job Spec | Background job logic, external API calls | Medium |
| System Spec | Critical UI flows, JavaScript interactions | Slow |
| Cucumber Feature | Business scenarios, acceptance criteria | Slow |

### Rules

1. **Model specs**: Test all validations, scopes, and methods. Use `build` over `create` when possible.
2. **Policy specs**: Test all CRUD actions for all roles. Use shared examples.
3. **Component specs**: Test rendering, slots, and edge cases. Use `render_inline`.
4. **Request specs**: Test response codes and JSON structure. Don't test UI.
5. **System specs**: Only for critical user journeys. One flow per test.
6. **Cucumber**: Business-readable. One scenario per acceptance criterion.

## Implementation Phases

1. Foundation Setup (gems, config, move legacy tests)
2. Normal Island Data & Factories
3. Model Specs
4. Component Specs
5. Policy Specs
6. Request Specs
7. Job Specs (Calendar Importer)
8. System Specs
9. Cucumber Features
10. Development Seeds & Cleanup
