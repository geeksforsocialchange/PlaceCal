# Admin UI Redesign: Bootstrap to Tailwind Migration

- Author: @kimadactyl
- Deciders: TBD
- Date: 2026-01-07
- Status: **Proposed**

## Context and Problem Statement

The PlaceCal admin UI is built on Bootstrap 4.6.2 with jQuery-dependent libraries (Select2, DataTables). While functional, the stack is aging and has several issues:

- Bootstrap 4 is no longer actively developed (5.x is current)
- jQuery dependency adds bundle weight and limits modern JS patterns
- Select2 and DataTables are jQuery-dependent, creating upgrade friction, and are horrible to work with
- The Partners form is 195 lines long and overwhelming for users
- Current UI patterns don't align with modern admin dashboard expectations

We need a modernised admin interface that:

- Uses contemporary, actively maintained frontend tools
- Removes jQuery dependency entirely
- Provides better UX for complex forms (especially Partners)
- Maintains all existing functionality with comprehensive test coverage

## Decision Drivers

- Remove jQuery to reduce bundle size and enable modern JS patterns
- Improve user experience for complex data entry (Partners form)
- Use actively maintained libraries with strong communities
- Ensure safe migration through comprehensive test coverage first
- Align with existing Stimulus/Turbo architecture

## Considered Options

### CSS Framework

1. **Tailwind CSS** - Utility-first, highly customizable, great Stimulus integration
2. **Bulma** - Class-based like Bootstrap, simpler migration, smaller ecosystem
3. **Bootstrap 5** - Least effort, familiar patterns, still large bundle

### Select Dropdown Replacement

1. **Tom Select** - Vanilla JS, similar API to Select2, no jQuery
2. **Choices.js** - Vanilla JS, different API, requires more migration
3. **Headless UI Combobox** - React-based, requires more infrastructure

### Data Table Replacement

1. **Custom Stimulus controller** - Vanilla JS, consistent with existing architecture
2. **TanStack Table (React Table v8)** - Modern but introduces React dependency
3. **AG Grid** - Feature-rich but heavy, commercial licensing concerns
4. **Keep DataTables** - jQuery dependent, blocks full jQuery removal

### Multi-step Form Approach

1. **Turbo Frames + Stimulus** - Server-rendered steps, Rails-native
2. **Client-side wizard (Stimulus only)** - All steps in DOM, show/hide
3. **Single page with tabs** - Simpler but still overwhelming

## Decision Outcome

| Component        | Old                  | New                        | Rationale                                         |
| ---------------- | -------------------- | -------------------------- | ------------------------------------------------- |
| CSS Framework    | Bootstrap 4.6.2      | Tailwind CSS               | Modern, no jQuery, excellent Stimulus integration |
| Select Dropdowns | Select2              | Tom Select                 | Vanilla JS, similar API, easy migration           |
| Data Tables      | DataTables.js        | Custom Stimulus controller | Vanilla JS, consistent architecture, no jQuery    |
| Form Wizard      | Single 195-line form | Turbo Frames + Stimulus    | Server-rendered steps, Rails-native, better UX    |

### Positive Consequences

- Complete removal of jQuery dependency
- Significantly reduced bundle size
- Modern, maintainable codebase
- Better user experience for complex data entry
- Active communities and ongoing development for all chosen tools
- Tailwind's utility-first approach works excellently with ViewComponent

### Negative Consequences

- Learning curve for Tailwind utility classes
- Migration effort required across all admin views
- Temporary dual stylesheets during migration
- Custom table component requires more initial development than off-the-shelf solution

---

## Implementation Phases

| Phase | Description                                              | Status  |
| ----- | -------------------------------------------------------- | ------- |
| 1     | Comprehensive Cucumber Test Coverage                     | Pending |
| 2     | Tailwind CSS Setup (parallel with Phase 1)               | Pending |
| 3     | Component Migration (layout, forms, Select2, DataTables) | Pending |
| 4     | Multi-Step Partners Form                                 | Pending |
| 5     | Bootstrap/jQuery Removal and Cleanup                     | Pending |

---

## Phase 1: Comprehensive Cucumber Tests

Lock down existing behavior before any UI changes.

### Fix Existing Features

Remove `@wip` tags and ensure these pass:

- `features/admin/partner_management.feature`
- `features/admin/calendar_management.feature`
- `features/admin/sites.feature`
- `features/admin/tags.feature`
- `features/admin/articles.feature`
- `features/admin/user_management.feature`

### Expand Partners Feature

Create comprehensive scenarios for:

- CRUD operations with DataTable
- Address and service areas (nested Cocoon forms)
- Opening times (Stimulus controller)
- Select2 associations (partnerships, categories, facilities)
- Image upload and preview
- Moderation (hidden status)
- Permission levels (root, partner admin, neighbourhood admin)

### Add Missing Features

- `features/admin/neighbourhoods.feature`
- `features/admin/collections.feature`
- `features/admin/supporters.feature`
- `features/admin/dashboard.feature`

### New Step Definitions

- `features/step_definitions/select2_steps.rb` - Select2 interactions
- `features/step_definitions/opening_times_steps.rb` - Opening times picker
- `features/step_definitions/file_upload_steps.rb` - Image uploads

**Acceptance:** All Cucumber tests pass, 100% admin route coverage

---

## Phase 2: Tailwind CSS Setup

### Install Dependencies

```bash
yarn add tailwindcss autoprefixer postcss
```

### Configuration Files

- `tailwind.config.js` - Content paths, PlaceCal brand colors, `tw-` prefix for coexistence
- `postcss.config.js` - PostCSS configuration

### Parallel Stylesheet

- `app/assets/stylesheets/admin_tailwind.css` - New Tailwind entry point
- Add build script: `"build:css:tailwind"` in package.json

### Dual-Mode Layout

Create `app/views/layouts/admin/application_tailwind.html.erb` that includes both stylesheets during migration.

**Acceptance:** Tailwind compiles, `tw-*` classes work alongside Bootstrap

---

## Phase 3: Component Migration

### 3.1 Layout Components

1. `app/components/admin_flash.rb` - Alert styling
2. `app/views/layouts/admin/_admin_topbar.html.erb` - Navbar
3. `app/views/layouts/admin/_admin_navigation.html.erb` - Sidebar
4. `app/views/layouts/admin/application.html.erb` - Main grid

### 3.2 Replace Select2 with Tom Select

```bash
yarn add tom-select
```

**Files to modify:**

- `app/javascript/controllers/select2_controller.js` → `tom_select_controller.js`
- All views using `data-controller="select2"` → `data-controller="tom-select"`

**Views with Select2:**

- `app/views/admin/partners/_form.html.erb`
- `app/views/admin/users/_form.html.erb`
- `app/views/admin/calendars/_form.html.erb`
- `app/views/admin/sites/_form.html.erb`
- `app/views/admin/articles/_form.html.erb`
- `app/views/admin/tags/_form.html.erb`

### 3.3 Replace DataTables with Stimulus Controller

**Create:**

- `app/javascript/controllers/data_table_controller.js` - Custom Stimulus table controller
- `app/components/admin/data_table_component.rb` - ViewComponent with Stimulus bindings

**Features:**

- Server-side pagination (existing JSON endpoints)
- Sorting (click column headers)
- Search/filtering (debounced input)
- Turbo Frame integration for seamless updates
- Responsive design with Tailwind

**Datatable classes to update (keep JSON format):**

- `app/datatables/partner_datatable.rb`
- `app/datatables/calendar_datatable.rb`
- `app/datatables/user_datatable.rb`
- `app/datatables/site_datatable.rb`
- `app/datatables/article_datatable.rb`
- `app/datatables/tag_datatable.rb`
- `app/datatables/neighbourhood_datatable.rb`

### 3.4-3.6 Form Migration (Simple → Medium → Complex)

**Simple Forms:**

- `app/views/admin/tags/_form.html.erb`
- `app/views/admin/collections/_form.html.erb`
- `app/views/admin/supporters/_form.html.erb`
- `app/views/admin/articles/_form.html.erb`

**Medium Forms:**

- `app/views/admin/users/_form.html.erb`
- `app/views/admin/calendars/_form.html.erb`
- `app/views/admin/neighbourhoods/_form.html.erb`

**Complex Forms:**

- `app/views/admin/sites/_form.html.erb`
- Partners form (Phase 4)

### 3.7 Tailwind Simple Form Config

- Create `config/initializers/simple_form_tailwind.rb`

### 3.8 New Admin ViewComponents

- `app/components/admin/card_component.rb`
- `app/components/admin/form_section_component.rb`
- `app/components/admin/button_component.rb`

**Acceptance:** Each component has no Bootstrap classes, all Cucumber tests pass

---

## Phase 4: Multi-Step Partners Form

Convert 195-line form into Turbo Frame wizard with 5 steps (4 for edit).

### Step Structure

| Step                 | Content                                              | When          |
| -------------------- | ---------------------------------------------------- | ------------- |
| 1. Initial           | Name and address (required to create)                | Create only   |
| 2. Basic Information | Summary, description, accessibility, image, all tags | Create + Edit |
| 3. Place             | Service areas, opening times                         | Create + Edit |
| 4. Contact           | Website, social media, public + partnership contacts | Create + Edit |
| 5. Admin             | Event matching, moderation (hidden status)           | Create + Edit |

### Files to Create

**Step Views:**

- `app/views/admin/partners/steps/_initial.html.erb`
- `app/views/admin/partners/steps/_basic_info.html.erb`
- `app/views/admin/partners/steps/_place.html.erb`
- `app/views/admin/partners/steps/_contact.html.erb`
- `app/views/admin/partners/steps/_admin.html.erb`

**Stimulus Controller:**

- `app/javascript/controllers/multi_step_form_controller.js`

**ViewComponent:**

- `app/components/admin/multi_step_form_component.rb`

### Controller Updates

Add to `app/controllers/admin/partners_controller.rb`:

- `step` action - Render individual step
- `save_step` action - Save and advance

### Routes

```ruby
resources :partners do
  member do
    get 'step/:step', to: 'partners#step', as: :step
    patch 'save_step/:step', to: 'partners#save_step', as: :save_step
  end
end
```

**Acceptance:** Multi-step navigation works, state persists, all tests pass

---

## Phase 5: Bootstrap/jQuery Removal

### Remove JavaScript Imports

From `app/javascript/admin.js`:

- Remove `import "bootstrap"`

### Remove CSS Imports

From `app/assets/stylesheets/admin.scss`:

- Remove `@import "bootstrap"`

### Remove Packages

**From `package.json`:**

- `bootstrap`, `popper.js`
- `select2`
- `datatables.net-*`

**Note:** jQuery remains for public frontend; admin will no longer depend on it.

**From `Gemfile`:**

- `gem 'bootstrap'`
- `gem 'select2-rails'`

### Update Simple Form

- Delete `config/initializers/simple_form_bootstrap.rb`
- Ensure Tailwind config is primary

**Acceptance:** No Bootstrap/jQuery/Select2/DataTables in codebase, bundle size significantly reduced, all tests pass

---

## Critical Files

| File                                               | Purpose                                |
| -------------------------------------------------- | -------------------------------------- |
| `app/views/admin/partners/_form.html.erb`          | 195-line form to convert to multi-step |
| `config/initializers/simple_form_bootstrap.rb`     | Replace with Tailwind version          |
| `app/views/layouts/admin/application.html.erb`     | Main layout to migrate                 |
| `app/javascript/admin.js`                          | Remove Bootstrap/jQuery imports        |
| `app/javascript/controllers/select2_controller.js` | Replace with Tom Select                |
| `app/views/layouts/admin/_datatable.html.erb`      | Replace with Stimulus data table       |
| `features/admin/partner_management.feature`        | Expand for comprehensive coverage      |

---

## Sequencing

```
Phase 1 (Tests) ─────────────┐
                             ├──→ Phase 3 (Components) ──→ Phase 5 (Cleanup)
Phase 2 (Tailwind Setup) ────┤
                             └──→ Phase 4 (Multi-Step) ──┘
```

Phase 1 and 2 can run in parallel. Phase 3 and 4 can partially overlap. Phase 5 requires 3+4 complete.

---

## References

- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Tom Select Documentation](https://tom-select.js.org/)
- [TanStack Table Documentation](https://tanstack.com/table/latest)
- [Turbo Frames Documentation](https://turbo.hotwired.dev/reference/frames)
