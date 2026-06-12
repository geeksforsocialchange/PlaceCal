# Email Subscription and Consent Architecture

- Author: @kimadactyl
- Date: 2026-06-12
- Status: **Proposed**

## Context and Problem Statement

PlaceCal needs to email partners regularly (issue #3256): a recurring digest reminding partner admins they have an account, showing the state of their listings and calendars, plus partnership-admin broadcasts and, later, partner onboarding/verification emails.

We currently have no email preference or consent storage of any kind. Worse, our consent position is a grey zone: many partners were opted in verbally during in-person onboarding with no record kept, and our privacy policy claims **consent** as our sole lawful basis for all processing — the weakest possible claim when no consent records exist.

We need an architecture that (a) supports a growing number of email types without confusion, (b) turns our undocumented history into a defensible audit trail, and (c) bakes GDPR compliance into the software rather than around it.

## Decision Drivers

- Email list types will multiply (digest, partnership updates, citizen listings, secretary digests, partner verification…) — the design must scale without a migration per list
- Mixed opt-in/opt-out semantics: some lists are legitimate-interests service emails (opt-out), others require explicit consent (opt-in); encoding polarity in column names (`opted_out_at` vs `consented_at`) is confusing and error-prone
- UK GDPR accountability principle: we must be able to demonstrate what each person consented to, when, and how — including honestly recording the pre-system verbal-consent era
- ICO enforcement precedent (Honda/Flybe): a standalone "please confirm your consent" email is itself unlawful marketing; re-permissioning must ride inside lawful service email
- Gmail/Yahoo bulk-sender requirements: one-click unsubscribe headers are mandatory
- Enforcement must be impossible to bypass accidentally — a forgotten check at one call site must not be able to email an unsubscribed user

## Considered Options

1. **Per-type columns on `users`** (e.g. `partner_reminder_emails_opted_out_at`, `partnership_update_emails_consented_at`)
2. **A normalized `email_subscriptions` table + a code-side list registry** defining each list's default policy
3. **Third-party preference management** (MailerSend suppression lists / external consent platform)

## Decision Outcome

**Option 2: subscriptions table + code-side registry.**

- An `EmailList` registry (frozen code config, not a DB table) defines each list: key, i18n name/description, and `default_policy` of `:opt_out` (no row = subscribed) or `:opt_in` (no row = not subscribed). List polarity lives in exactly one place.
- An `email_subscriptions` table holds one row per (user, list): an **explicit `subscribed` boolean** that means the same thing regardless of list polarity, plus `source` (profile_page / unsubscribe_link / admin / legacy_onboarding) and timestamps. Unique index on `[user_id, list_key]`.
- An append-only `email_subscription_events` table records every change (old/new value, source, actor, timestamp) — the consent audit trail. Scoped to email consent only; deliberately **not** a general activity log (that is #2371's territory).
- A single guard (`EmailSubscription.subscribed?(user, list_key)`) is enforced in a mailer concern, centrally — not at call sites.
- Adding a new email type is a registry entry plus i18n: no migration, and the preferences page picks it up automatically.

### Lawful basis positions (recorded here for the avoidance of doubt)

- `partner_digest` (quarterly): **service message to account holders under legitimate interests** — opt-out. Documented in a Legitimate Interests Assessment held outside the codebase.
- `partnership_updates` (broadcasts): **explicit opt-in consent**. The list starts empty; no legacy seeding.
- The privacy policy's "we rely on your consent" wording is corrected to a three-basis position (contract / legitimate interests / consent) **before the first send**, alongside a plain-English "Emails we send you" section.

### Transitional (legacy consent) handling

Existing partner-admin users are seeded onto `partner_digest` with `subscribed: true, source: 'legacy_onboarding'` plus a matching event. This records the verbal-consent history honestly rather than implying it by absence of data. The first digest carries an extended first-contact intro and acts as the re-permissioning moment (preferences link inside a lawful service email — never a standalone consent-request email, per Honda/Flybe).

## Consequences

### Positive

- One queryable source of truth for "can we email this person on this list", with polarity defined once
- Consent history is demonstrable (accountability principle) including the pre-system era, with `legacy_onboarding` always distinguishable from affirmative user action
- New email types (citizen listings, secretary digests, partner verification — see superseded #817/#2256) are additive registry entries
- Central guard makes "accidentally emailed an unsubscribed user" a structural impossibility rather than a code-review hope

### Negative

- Slightly more indirection than boolean columns: reading a user's effective state requires combining row + registry default
- The registry/table split means list definitions live in code while state lives in the DB — both must be consulted when debugging
- Append-only events table grows unboundedly (acceptable: low write volume, and it is the audit trail)

### Neutral / follow-ups

- MailerSend's own suppression list (hard bounces, spam complaints) remains a second, provider-side gate; bounce sweeps feed a partner re-onboarding worklist
- `List-Unsubscribe` / `List-Unsubscribe-Post` headers are set on all list email
- Implementation plan, phases, and launch runbook: `doc/proposals/3256-partner-email-notifications-prompt.md`
