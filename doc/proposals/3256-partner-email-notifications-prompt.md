# Implementation prompt: Partner email notifications + email consent compliance

> **Issue**: https://github.com/geeksforsocialchange/PlaceCal/issues/3256 (supersedes #817, #1440, #2256, #2278)
> **ADR**: doc/adr/0015-email-subscription-and-consent-architecture.md
> **How to use**: feed this file to a Claude Code session as the implementation brief. Work phase by phase — Phase 1 first, one PR per phase. Part A (legal) and Part C (runbook) are human workstreams included for context; the launch gates in Part C apply before any production send.

## Why

PlaceCal onboards partner organisations once, links their calendar, and the events keep flowing — but the human contact moves on, forgets they have an account, or loses their login. Listings drift stale and we have no regular contact channel.

At the same time, our consent position is a grey zone: many partners were opted in verbally during in-person onboarding and we hold no record, and our privacy policy currently (wrongly) claims **consent** as our sole lawful basis for everything — the worst possible basis to claim when you have no consent records.

This ticket fixes both together: a recurring partner email system with proper subscription machinery, and the legal/policy work that makes the first send the moment our grey zone becomes a documented, defensible position.

**Supersedes:** #817 (regular up-to-date confirmation emails → Phase 2), #1440 (organisers emailing their networks → Phase 4), #2278 (invite-a-partner nudge button → Phases 3 & 5), #2256 (active consent from new partners → Phases 1 & 5). Uncovered remainders from those issues are explicitly scoped below so nothing is silently dropped.

**Not legal advice; positions below should be sanity-checked against current ICO guidance before first send.**

---

## Part A — Legal & policy workstream (mostly humans, not code)

**A1. Write the Legitimate Interests Assessment (LIA).** One page, internal: purpose (keeping published community information accurate — in partners' interest too), necessity (email is the only channel we hold), balancing test (account holders reasonably expect service email about their listing; easy opt-out provided). This is the documented basis for sending the digest to everyone, including the no-records legacy population. **Must exist before first send.**

**A2. Update the privacy policy** (code — Phase 1, item 6). Key correction: replace the "we rely on your consent" line with the three-basis position (contract for accounts, legitimate interests for service operation and digest emails, consent for opt-in lists), and add a plain-English "Emails we send you" section including an honest paragraph about the transitional state ("many partners signed up in person before we recorded preferences; our reminder emails are how we invite you to set them properly"). Plain English is the legally required register (UK GDPR Art 12), not a simplification of it. **Must deploy before or with first send.**

**A3. Check the DUAA 2025 charity soft opt-in.** The Data (Use and Access) Act 2025 extended PECR's soft opt-in to charities furthering their charitable purposes. Confirm commencement status and whether GFSC/PlaceCal's structure qualifies. If yes, it's extra cover for the `partnership_updates` list; we still default that list to explicit opt-in, but it changes our risk posture for borderline cases (e.g. unincorporated community groups, who count as "individual subscribers" under PECR).

**A4. The Honda/Flybe constraint (hard rule).** We never send a standalone "please confirm your consent" email — asking for consent is itself marketing, and the ICO has fined for exactly this. All re-permissioning happens _inside_ the lawful service email (the digest), via the preferences link.

**A5. First-edition copy gets a human pass.** The first digest does triple duty: reintroduction ("PlaceCal here, you have an account because…"), transparency notice (privacy policy updated, here's how we'll email you), and re-permissioning (opt in to partnership updates here). Highest-leverage copywriting in the project — PHT signs it off, not placeholder copy.

**A6. Record history honestly.** Seed legacy users' subscriptions with `source: 'legacy_onboarding'` (Phase 1.7) so the audit trail reads "verbal consent at onboarding, formalised by email on date X" rather than pretending records exist.

**Related, not blocking:** #2371 (log who created/updated partners/users/calendars) is a provenance concern. This ticket's consent and delivery tables are separate and purpose-built — keep them narrow, don't grow them into a general activity log — but they contribute toward #2371's audit goals.

---

## Part B — Technical implementation

### Existing architecture (verified, don't rediscover)

- **Partner** `has_and_belongs_to_many :users` (these are partner admins), `has_many :calendars, foreign_key: :organiser_id`. Some partners have **no calendar at all**. Contact fields exist: `admin_email`, `partner_email`, `public_email`.
- **Partnership** is an STI subclass of Tag (`type = 'Partnership'`); partnership admins link via `tags_users`; `user.partnership_admin?` exists.
- **Calendar** sync state: `calendar_state` enum (`idle`/`in_queue`/`in_worker`/`error`/`bad_source`), `last_import_at`, `notices` (jsonb), `critical_error`.
- **User**: Devise (`:database_authenticatable, :recoverable, :invitable, :trackable`…). Roles: root, national_admin, editor, citizen. **No email preference/consent columns exist anywhere.**
- **Mailers**: `ApplicationMailer` (from `no-reply@placecal.org`), `DeviseMailer`, `ModerationMailer`, `JoinMailer`. Production delivery: MailerSend SMTP. Mailer views are Phlex (`Views::Mailers::...`).
- **Jobs**: Delayed::Job, self-rescheduling recurring pattern — `config/initializers/recurring_jobs.rb`, `app/jobs/concerns/self_rescheduling.rb`, `RecurringCalendarScanJob` as template. No cron.
- Admin sign-in: `https://admin.placecal.org/users/sign_in`. Public partner pages: `https://placecal.org/partners/:slug`.
- i18n mandatory — no hardcoded user-facing strings (`config/locales/en.yml` / `admin.en.yml`). RSpec. Follow `doc/ai/prompts/views.md` and `tests.md`.

### Phase 1 — Subscription & consent foundation

Build this first; everything depends on it. **Do not add per-email-type columns to `users`** — lists will multiply and mixed opt-in/opt-out column polarity is confusing.

1. **List registry in code** (e.g. `EmailList` — frozen config, not a DB table): each list has a key, i18n name/description, and `default_policy` of `:opt_out` (no row = subscribed) or `:opt_in` (no row = not subscribed). Initial lists:
   - `partner_digest` — recurring partner reminder. Policy: **opt_out** (service email under legitimate interests).
   - `partnership_updates` — partnership-admin broadcasts. Policy: **opt_in** (explicit consent).
2. **`email_subscriptions` table**: `user_id`, `list_key`, `subscribed` (explicit boolean — same meaning regardless of list polarity), `source` (profile_page / unsubscribe_link / admin / legacy_onboarding), timestamps. Unique on `[user_id, list_key]`. One model answers `EmailSubscription.subscribed?(user, :partner_digest)` by combining row state with registry default. Polarity lives in exactly one place (the registry).
3. **Append-only `email_subscription_events`** (user, list_key, old/new value, source, actor, timestamp) — the consent audit trail. Email-consent scope only; not a general activity log.
4. **Signed, no-login preferences page** (message-verifier / signed-id token with expiry) listing all lists with checkboxes. Every outbound email footer links to it. Set `List-Unsubscribe` + `List-Unsubscribe-Post` headers (one-click unsubscribe — Gmail/Yahoo require them; MailerSend supports them).
5. **Admin profile checkboxes** for the same lists, with i18n copy explaining each.
6. **Privacy policy update** in `Views::Homepage::Privacy`: revised lawful-basis wording and new "Emails we send you" section (draft copy attached to this ticket); also fix the duplicated intro paragraphs, the dangling Plausible link, and remove the meaningless blanket-consent section.
7. **Transitional seeding** (migration): for every existing partner-admin user, seed a `partner_digest` row with `subscribed: true, source: 'legacy_onboarding'` plus a matching event, so historical state is explicit rather than implied by absence. Do **not** seed any `partnership_updates` rows — that list starts empty and fills only via affirmative action. `source` values must always distinguish `legacy_onboarding` from real user actions.
8. **Central enforcement**: every outbound email type passes through the subscription guard in a mailer concern — not at call sites.

### Phase 2 — Recurring partner digest _(absorbs #817)_

Periodic email to every user administering ≥1 partner, subject to the `partner_digest` check. Interval configurable; **default quarterly**. One email per user covering all their partners.

Content:

- You have a PlaceCal account on this address; sign-in link; "forgotten your password?" link into the Devise reset flow.
- Per partner: name, public page link, and a calendar/events section with **three distinct states**:
  - **Healthy feed**: connected feed(s), "last synced N days ago" (`last_import_at`), next ~5 upcoming events + "see all" link.
  - **Failing feed**: plain-language explanation from `calendar_state`/`critical_error`, link to fix in admin.
  - **No calendar linked**: don't imply breakage — "you don't have an events feed connected; here's how to link one, or add events manually", plus any manually-added upcoming events.
- Prominent **"Confirm everything is up to date"** button: signed one-click link (no login) writing `info_confirmed_at` on Partner plus who/how; surfaced in the admin partner index as a staleness indicator. Landing page thanks them and offers sign-in to edit.
- **First-contact variant**: when `partner_digest_last_sent_at` is nil, render the extended intro — what PlaceCal is, why this email, privacy policy updated, how to set preferences (the A5 copy). Later digests use a short standard intro. Same mailer/template; i18n copy variant only.

Implementation:

- `RecurringPartnerDigestJob` following the self-rescheduling pattern, seeded in `config/initializers/recurring_jobs.rb`, with an Appsignal check-in (like `calendar_scan`).
- Track last-sent per user; job is idempotent; interval enforced per-user, not per-run.
- Recurring job only enqueues one Delayed::Job per user (staggered) — no inline sending.
- HTML + plain-text parts; `ActionMailer::Preview`s for every variant.
- RSpec: unsubscribed skipped, no-partner users skipped, all three calendar-state variants, first-contact vs standard intro, confirm-token round trip + expiry, registry default-policy resolution.

**Out of scope (from #817, deliberately):** citizen weekly area listings and secretary change digests. The list registry makes these straightforward later additions (new registry entries, opt-in), but they are not part of this ticket.

### Phase 3 — Partner admin tools _(absorbs part of #2278)_

- **Resend invitation / login help**: on the partner's user list and user edit page, a button to re-send the Devise invitation (never accepted) or a password-reset email (accepted). Use existing `:invitable`/`:recoverable` machinery — no parallel flow, never email a password. Pundit-authorised consistent with existing policies.

### Phase 4 — Partnership admin broadcasts _(absorbs #1440)_

- Compose form in admin (subject + plain textarea to start) with recipient preview ("N people across M partners") and a confirm step.
- Recipients: admins of partners tagged with that partnership, **filtered through the `partnership_updates` opt-in check**. Show the sender how many were excluded for lack of consent.
- One job per recipient; BCC-style privacy (never expose the list); from `no-reply@placecal.org`, reply-to the partnership admin.
- Sent-broadcasts log (sender, partnership, subject, timestamp, recipient count) visible to root/national admins — this is #1440's "log of emails sent".
- Cap: one broadcast per partnership per day initially.
- **Extension (from #1440):** recipient scoping by neighbourhood and site, not just partnership tag. Build recipient resolution as a shared service (`partnership:`, `neighbourhood:`, `site:` scopes) even if only the partnership scope ships first, so the others are additive.

### Phase 5 — Partner onboarding consent & verification _(absorbs #2256 and the rest of #2278)_

Builds directly on the Phase 1 infrastructure; can ship as a follow-up PR but is in scope for this ticket.

- **Consent provenance at creation**: when an organiser creates a partner, record how/where consent was obtained (Mailchimp-style basis dropdown: "asked in person on [date]", "they emailed us", "public listing", etc.) — stored against the partner, append-only, same honest-record philosophy as `legacy_onboarding`.
- **Verify-before-visible flow**: organisers can (optionally at first) add a partner as _unlisted_; the named contact receives a nicely formatted invitation email with a signed verify link; the partner becomes publicly visible only when clicked. Verification click writes the consent record. Allow bypass for root (and possibly per-site policy) pending the "do we enforce for everyone" research question from #2256.
- **Invite-a-partner nudge (#2278)**: a button for organisers/partner admins to send the invitation email to a prospective partner (e.g. the Dalston community cafe case) instead of telling them to email support — reuses the same invitation mailer and consent recording.
- **Future:** partnership managers requesting to add an _existing_ partner to their partnership (accept/decline emails to partner admins). Keep recipient-resolution and notification plumbing reusable (a shared "notify the admins of partner X" service); each future email type is just a new registry entry — no migration.

### General requirements

- All strings via i18n. Phlex mailer views per existing `Views::Mailers::Devise::*` patterns. Strong params, Pundit, RSpec across models/mailers/jobs/requests. Reversible migrations.
- Every outbound email type must pass through the subscription guard — enforced centrally, not at call sites.

---

## Part C — Launch runbook

### Pre-launch checklist (all must be true before first send)

- [ ] LIA written and filed (A1)
- [ ] Privacy policy updated and **deployed to production** (A2 / Phase 1.6)
- [ ] DUAA charity soft opt-in question answered and noted (A3)
- [ ] First-edition copy signed off by PHT (A5)
- [ ] MailerSend domain authentication verified: SPF, DKIM, DMARC all passing — a bulk send from a misconfigured domain torches deliverability
- [ ] `List-Unsubscribe` headers verified in a real received email (Gmail "unsubscribe" link appears next to sender)
- [ ] Legacy seeding migration run; spot-check `source: 'legacy_onboarding'` rows and that `partnership_updates` is empty
- [ ] Test sends to all staff: every variant (healthy / failing / no calendar, first-contact / standard), HTML + plain text, desktop and phone
- [ ] Confirm-button and preferences-page token round trips tested in staging, including expired tokens
- [ ] Recipient count pulled from production console and eyeballed — does the number look right? Any obviously dead domains?
- [ ] support@placecal.org staffed for launch week; team briefed on likely replies ("who are you?", "delete my account", "how do I log in?")

### First send (the transition moment)

1. Send to staff + a handful of friendly partners first; wait 24h; check rendering, bounces, replies.
2. Send the remainder in batches over several days (e.g. 25–33%/day), not one blast — protects deliverability and keeps support load sane. Check MailerSend bounce/complaint rates between batches; **pause if complaint rate approaches 0.1–0.3%** (Gmail's enforcement threshold).
3. Watch the Appsignal check-in and Delayed::Job queue depth during sends.

### Post-launch (first two cycles)

- Weekly: review unsubscribes, opt-ins to `partnership_updates`, confirm-button clicks. These are also engagement data — which partners are alive?
- Sweep hard bounces: a bouncing admin email = a stale partner contact. Feed these to PHT as a re-onboarding worklist (this is half the point of the project).
- Handle replies/SARs: `email_subscription_events` answers "what did this person consent to and when".
- After two digest cycles: transition window closes — anything marketing-flavoured goes only to recorded opt-ins from then on. Note the date.

### Ongoing operations

- **Pause switch**: document how to stop the recurring job (delete the Delayed::Job / feature flag) — needed if a bad batch goes out.
- Appsignal alert if the digest check-in goes silent past its interval.
- Quarterly, before each send: re-run the rendering spot-check against current data; review bounce list growth.
- When adding any new email type: registry entry + i18n + policy "Emails we send you" section updated in the same PR.

---

## Appendix — Draft privacy policy copy (A2 / Phase 1.6)

**Replace the lawful-basis line** ("…the lawful basis we rely on for processing this information is your consent") with:

> Under the UK General Data Protection Regulation (UK GDPR), the lawful bases we rely on are:
>
> - **Contract** — when you create an account, we process your details so we can provide the service you signed up for.
> - **Legitimate interests** — we process partner and event information so we can publish accurate community information, which is the whole point of PlaceCal. This includes occasionally emailing account holders about the state of their account and listings.
> - **Consent** — for optional emails like partnership updates. You choose these yourself, and you can change your mind at any time.

**New section, "Emails we send you"** (after "Personal Information"):

> If you have a PlaceCal account, we'll email you from time to time:
>
> - **Account and listing emails** — a regular (roughly quarterly) reminder that you have an account, what's published on your listing, whether your events feed is working, and how to sign in. We send these so the information we publish about your organisation stays accurate. You can stop them with one click in any email.
> - **Partnership updates** — if your organisation belongs to a partnership (like a local network of organisations), the people coordinating it can send occasional updates. **We only send these if you've opted in.**
> - **Essential emails** — things like password resets and invitations. These only arrive when you (or someone managing your organisation) asks for them.
>
> Every email we send links to a preferences page where you can change what you receive, without needing to log in.
>
> **If you joined PlaceCal a while ago:** many of our partners signed up in person, before we had a system for recording email preferences. We email existing account holders on the basis described above, and our reminder emails are also how we invite you to set your preferences properly. If you'd rather we didn't email you at all, one click sorts it.
