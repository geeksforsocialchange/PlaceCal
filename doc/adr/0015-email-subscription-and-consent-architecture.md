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
- The implementation phases and launch runbook are recorded below (folded in from the original #3256 implementation brief)

## Legal & policy gates

These are human workstreams, not code, but they gate the first production send. Recorded here so the runbook checklist below is self-contained. **Not legal advice — sanity-check against current ICO guidance before first send.**

- **LIA** — a one-page Legitimate Interests Assessment for the digest: purpose (keeping published community information accurate, in partners' interest too), necessity (email is the only channel we hold), balancing test (account holders reasonably expect service email about their listing; easy opt-out provided). Documented basis for sending to everyone including the no-records legacy population. **Must exist before first send.**
- **Privacy policy** (shipped as Phase 1 code) — replace the "we rely on your consent" line with the three-basis position (contract / legitimate interests / consent) and add a plain-English "Emails we send you" section, including an honest paragraph about the transitional verbal-consent state. Plain English is the legally required register (UK GDPR Art 12). **Must deploy before or with first send.**
- **DUAA 2025 charity soft opt-in** — the Data (Use and Access) Act 2025 extended PECR's soft opt-in to charities furthering their charitable purposes. Confirm commencement status and whether GFSC/PlaceCal qualifies; if so it is extra cover for `partnership_updates`, though that list still defaults to explicit opt-in.
- **Honda/Flybe (hard rule)** — never send a standalone "please confirm your consent" email; asking for consent is itself marketing and the ICO has fined for it. All re-permissioning rides inside the lawful service email (the digest), via the preferences link.
- **First-edition copy** — the first digest does triple duty (reintroduction, transparency notice, re-permissioning). Highest-leverage copy in the project; GFSC CIC signs it off, not placeholder text.
- **Honest history** — legacy users' subscriptions are seeded with `source: 'legacy_onboarding'` so the audit trail reads "verbal consent at onboarding, formalised by email on date X" rather than implying records that never existed.

Related but not blocking: #2371 (provenance log of who created/updated partners/users/calendars). The consent and delivery tables here are separate and purpose-built — keep them narrow, don't grow them into a general activity log.

## Implementation phases

One PR per phase; Phase 1 is the foundation everything else depends on. Supersedes #817, #1440, #2256, #2278 — the phase notes record where each is absorbed.

### Phase 1 — Subscription & consent foundation

1. **List registry in code** (`EmailList`, frozen config) — each list has a key, i18n name/description, and `default_policy` (`:opt_out` / `:opt_in`). Initial lists: `partner_digest` (opt-out, legitimate interests) and `partnership_updates` (opt-in, explicit consent).
2. **`email_subscriptions` table** — `user_id`, `list_key`, explicit `subscribed` boolean, `source`, timestamps; unique on `[user_id, list_key]`.
3. **`email_subscription_events`** (append-only) — the consent audit trail; email-consent scope only.
4. **Signed, no-login preferences page** (message-verifier / signed-id with expiry) listing all lists with checkboxes; linked from every footer. Sets `List-Unsubscribe` + `List-Unsubscribe-Post` headers.
5. **Admin profile checkboxes** for the same lists, with i18n explanatory copy.
6. **Privacy policy update** in `Views::Homepage::Privacy` — the three-basis wording and "Emails we send you" section (see Legal & policy gates).
7. **Transitional seeding** (migration) — seed every existing partner-admin user a `partner_digest` row (`subscribed: true, source: 'legacy_onboarding'`) plus a matching event. Do **not** seed any `partnership_updates` rows.
8. **Central enforcement** — every outbound email type passes through the subscription guard in a mailer concern, not at call sites.

### Phase 2 — Recurring partner digest _(absorbs #817)_

Periodic email (default quarterly, interval configurable) to every user administering ≥1 partner, gated by the `partner_digest` check; one email per user covering all their partners. Per partner, three distinct calendar states: healthy feed (last-synced + upcoming events), failing feed (plain-language explanation + fix link), no calendar linked (don't imply breakage — how to connect one). Includes a signed one-click **"Confirm everything is up to date"** button writing `info_confirmed_at`, and a first-contact intro variant when `partner_digest_last_sent_at` is nil. Built as `RecurringPartnerDigestJob` on the self-rescheduling pattern with an Appsignal check-in; idempotent, per-user interval, one staggered Delayed::Job per user; HTML + plain-text parts; mailer previews and RSpec for every variant. **Out of scope (from #817):** citizen weekly area listings and secretary change digests — straightforward later registry additions.

### Phase 3 — Partner admin tools _(absorbs part of #2278)_

Resend-invitation / login-help buttons on the partner user list and edit page, reusing existing Devise `:invitable` / `:recoverable` machinery (never email a password); Pundit-authorised.

### Phase 4 — Partnership admin broadcasts _(absorbs #1440)_

Admin compose form (subject + textarea) with recipient preview and a confirm step. Recipients are admins of partners tagged with the partnership, filtered through the `partnership_updates` opt-in check (show how many were excluded). One job per recipient, BCC-style privacy, reply-to the partnership admin. Sent-broadcasts log visible to root/national admins (#1440's "log of emails sent"). Cap: one broadcast per partnership per day initially. Build recipient resolution as a shared service (`partnership:` / `neighbourhood:` / `site:` scopes) even though only partnership scope ships first.

### Phase 5 — Partner onboarding consent & verification _(absorbs #2256 and the rest of #2278)_

Consent provenance at partner creation (basis dropdown: asked in person on [date] / they emailed us / public listing…), stored append-only. Verify-before-visible flow: organisers add a partner as _unlisted_; the named contact gets a signed verify link; the partner becomes public only when clicked, and the click writes the consent record (root bypass allowed pending the #2256 enforcement question). Invite-a-partner nudge (#2278) reuses the same invitation mailer and consent recording. Keep recipient-resolution and "notify the admins of partner X" plumbing reusable so future email types are just new registry entries.

## Launch runbook

### Pre-launch checklist (all must be true before first send)

- [ ] LIA written and filed
- [ ] Privacy policy updated and **deployed to production**
- [ ] DUAA charity soft opt-in question answered and noted
- [ ] First-edition copy signed off by GFSC CIC
- [ ] MailerSend domain authentication verified: SPF, DKIM, DMARC all passing
- [ ] `List-Unsubscribe` headers verified in a real received email (Gmail "unsubscribe" link appears)
- [ ] Legacy seeding migration run; spot-check `source: 'legacy_onboarding'` rows and that `partnership_updates` is empty
- [ ] Test sends to all staff: every variant (healthy / failing / no calendar, first-contact / standard), HTML + plain text, desktop and phone
- [ ] Confirm-button and preferences-page token round trips tested in staging, including expired tokens
- [ ] Recipient count pulled from production console and eyeballed
- [ ] support@placecal.org staffed for launch week; team briefed on likely replies

### First send (the transition moment)

1. Send to staff + a handful of friendly partners first; wait 24h; check rendering, bounces, replies.
2. Send the remainder in batches over several days (~25–33%/day), not one blast. Check MailerSend bounce/complaint rates between batches; **pause if complaint rate approaches 0.1–0.3%** (Gmail's enforcement threshold).
3. Watch the Appsignal check-in and Delayed::Job queue depth during sends.

### Post-launch (first two cycles)

- Weekly: review unsubscribes, `partnership_updates` opt-ins, confirm-button clicks — also engagement data (which partners are alive).
- Sweep hard bounces into a GFSC CIC re-onboarding worklist (half the point of the project).
- Handle replies/SARs via `email_subscription_events` ("what did this person consent to and when").
- After two digest cycles the transition window closes — marketing-flavoured email then goes only to recorded opt-ins. Note the date.

### Ongoing operations

- **Pause switch**: document how to stop the recurring job (delete the Delayed::Job / feature flag).
- Appsignal alert if the digest check-in goes silent past its interval.
- Quarterly before each send: re-run the rendering spot-check; review bounce-list growth.
- Adding any new email type = registry entry + i18n + "Emails we send you" policy section, in the same PR.
