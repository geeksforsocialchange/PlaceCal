# Admin Roles & Permissions

PlaceCal has a layered permissions system. Users have a **database role** (stored in the `role` column) and also gain **derived roles** based on their associations with partners, neighbourhoods, partnerships, and sites.

## Database roles (enumerize)

Stored in `users.role`. Every user has exactly one:

| Role             | Description                                                                                     |
| ---------------- | ----------------------------------------------------------------------------------------------- |
| `root`           | Superadmin. Full access to everything.                                                          |
| `national_admin` | Not yet supported. Intended to manage all partners and count as a neighbourhood admin.          |
| `editor`         | Can edit all news articles. Only half-supported — was a stopgap for Trans Dimension publishing. |
| `citizen`        | Default role. No special powers — can only access things via derived roles.                     |

## Derived roles (from associations)

These are determined at runtime by checking what a user is associated with. A user can have multiple derived roles simultaneously.

### `neighbourhood_admin?`

**True when:** user is a `national_admin` OR has any neighbourhoods assigned (`neighbourhoods.any?`).

**What they can do:**

- See and edit partners within their neighbourhoods
- See and edit users associated with those partners
- Assign partners to users (`partner_ids`)
- Create calendars for partners in their scope
- View and edit neighbourhoods they own

**Cannot:** change user roles, delete users, manage sites, manage tags.

### `partner_admin?`

**True when:** user has any partners assigned (`partners.any?`).

**What they can do:**

- See and edit their own partners
- See and edit calendars for their partners
- See users associated with their partners
- Assign partners to users (`partner_ids`)
- Create and edit articles (if they have partners)

**Cannot:** change user roles, delete users, create new partners, manage neighbourhoods.

### `partnership_admin?`

**True when:** user has any tags of type `Partnership` assigned.

A partnership admin is a **restriction on top of neighbourhood admin** — they must also have neighbourhoods assigned for the role to be useful. Their scope is the intersection of their partnerships and their neighbourhoods: they can only see partners that match both.

**What they can do:**

- See partners that belong to their partnerships AND are within their neighbourhoods
- Assign partnerships to partners (`partnership_ids`)
- Create calendars for partners in their scope

**Requires:** both partnership tags AND neighbourhoods to be assigned. Without neighbourhoods, the partnership admin scope returns nothing useful.

### `site_admin?`

**True when:** user is set as the `site_admin` on any Site record (`Site.where(site_admin: self).any?`).

**What they can do:**

- View and edit the sites they administer
- Cannot create or destroy sites (root only)

**Note:** Site admin is a relatively narrow role — it only grants access to site settings, not to partners or users.

## How roles combine

A single user can be, for example, a `citizen` (database role) who is also a `partner_admin` (has partners assigned) and a `site_admin` (is admin of a site). The policies check each derived role independently.

The hierarchy in practice:

```
root (can do everything)
  neighbourhood_admin (partners in their neighbourhoods)
    partnership_admin (neighbourhood admin restricted to their partnerships)
    partner_admin (only their assigned partners)
  site_admin (site settings only)
  editor (articles only)
  citizen (nothing, unless given associations above)
```

## Key policy files

- `app/policies/user_policy.rb` — who can see/edit/create users
- `app/policies/partner_policy.rb` — who can see/edit/create partners
- `app/policies/calendar_policy.rb` — who can manage calendars
- `app/policies/site_policy.rb` — who can manage sites
- `app/policies/article_policy.rb` — who can manage articles
- `app/policies/neighbourhood_policy.rb` — who can manage neighbourhoods
- `app/policies/tag_policy.rb` — tags/partnerships (root only)

## Common gotcha

The `permitted_attributes_for_update` / `permitted_attributes_for_create` methods in policies must handle ALL roles that can reach the edit/create page. If a role is allowed by `edit?` / `create?` but not handled in the permitted attributes method, the method returns `nil` and the form crashes. Always include an `else` clause returning `[]`.
