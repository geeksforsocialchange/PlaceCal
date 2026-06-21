---
name: rails-hotwire-driver
description: >
  Drive PlaceCal's running local Rails dev server from the terminal without a
  browser — log in via Devise (CSRF handled automatically), submit forms,
  inspect Turbo Stream responses, and read the development log correlated by
  request id. Use this to actually exercise a change and verify it works (per
  CLAUDE.md's "never claim a fix worked until you've verified it") when the
  behaviour is server-rendered: a controller action, a redirect, a turbo-stream,
  the SQL a request runs, or an error in the log. It does NOT run JavaScript
  (no Stimulus, no DOM morphing) — for those, verify in Claude in Chrome (our
  standard for lvh.me), or optionally hand the logged-in session to a Playwright
  MCP via the bridge below. Pairs with static code reading (grep/Read) by adding
  live runtime interaction.
---

# Rails Hotwire Driver (PlaceCal)

Exercise PlaceCal's **running local dev server** from the shell: authenticate,
submit forms, trigger and read Turbo Streams, and read `log/development.log` —
all correlated by request id. This is the runtime complement to reading the code:
it tells you what the server _actually did_, not what it should do.

Vendored from [maquina-app/rails-claude-code](https://github.com/maquina-app/rails-claude-code)
(MIT), adapted for PlaceCal (Devise auth, `lvh.me` dev hosts). Source of truth
lives in `doc/ai/plugins/rails-hotwire-driver/`; `bin/setup-ai` installs it.

## When this fits (and when it doesn't)

**Good fit** — the server renders HTML and `text/vnd.turbo-stream.html` and you
are verifying that contract: a form posts and redirects, a turbo-stream replaces
the right target, the expected SQL ran, no error was logged.

**It will NOT execute JavaScript.** PlaceCal is importmap + Stimulus + Turbo, so
no Stimulus controllers run, no DOM morphing, no `requestSubmit`, no
ActionCable-broadcast rendering happens here. You can _see_ a broadcast in the
log via request-id correlation, but not its DOM effect. For anything
JS-dependent (did a Stimulus controller wire up, did a filter actually re-render,
did a map load), verify in **Claude in Chrome** — PlaceCal's standard for
`lvh.me` (per CLAUDE.md the preview tools don't work with it). If you need a
_scripted/headless_ browser instead, hand the logged-in session to a Playwright
MCP via the bridge below so you only log in once.

## Prerequisites

1. The dev server is running (`bin/dev`) and you know the host. PlaceCal uses:
   - **Public site:** `BASE_URL=http://lvh.me:3000`
   - **Admin:** `BASE_URL=http://admin.lvh.me:3000`
     `lvh.me` and `admin.lvh.me` both resolve to `127.0.0.1`; the subdomain rides
     in the `Host` header so Rails routes admin vs public correctly. The scripts
     only allow local hosts (`localhost`, `*.localhost`, `lvh.me`, `*.lvh.me`).
2. `Nokogiri` is available (it ships with PlaceCal's bundle). Run the Ruby
   scripts through the bundle: `bundle exec ruby <script>`.
3. **Recommended** for exact log correlation: add request-id tagging in
   `config/environments/development.rb`:
   ```ruby
   config.log_tags = [ :request_id ]
   ```
   Without it, `readlog.sh request` falls back to a context window — still
   useful, just noisier.

These scripts only ever talk to a local server and only read the **development**
log; `readlog.sh` refuses any path containing `production`.

## The scripts

All in `scripts/`. A shared cookie jar at `./.hotwire/cookies.txt` carries the
session across calls. `bin/setup-ai` symlinks this skill into
`.claude/skills/rails-hotwire-driver/`, so when run from the repo root the jar
and log resolve against the app.

### `scripts/req.sh` — one HTTP request, cookies persisted

```
BASE_URL=http://lvh.me:3000 req.sh GET /
BASE_URL=http://lvh.me:3000 req.sh GET /some-partner turbo     # Accept: turbo-stream
BASE_URL=http://admin.lvh.me:3000 req.sh GET /partners
```

Prints response headers (with `X-Request-Id`, `Set-Cookie` redacted), then the
body (truncated past `MAX_BYTES`, default 100k). Use the `X-Request-Id` to pull
that exact request's log lines.

### `scripts/submit_form.rb` — submit a form with the right CSRF token

**The primary tool for any POST/PUT/PATCH/DELETE.** It GETs the page, reads the
form's hidden inputs **including `authenticity_token`**, merges your fields over
them, and submits — eliminating the #1 hand-driving failure (a missing/stale
CSRF token). It honours Rails' `_method` hidden field for non-POST verbs.

PlaceCal uses **Devise**, whose login form has nested `user[...]` inputs:

```
# Log into admin as a site admin (session cookie lands in the jar):
BASE_URL=http://admin.lvh.me:3000 bundle exec ruby \
  doc/ai/plugins/rails-hotwire-driver/scripts/submit_form.rb \
  /users/sign_in "user[email]=admin@example.com" "user[password]=password"
```

Reports status, `X-Request-Id`, any redirect `Location`, and — for turbo-stream
responses — a parsed list of `action #target` pairs.

### `scripts/readlog.sh` — read the dev log safely

```
readlog.sh tail 200
readlog.sh grep 'SQL|SELECT' 500
readlog.sh request <x-request-id>   # exact lines for one request (needs log_tags)
```

### `scripts/flow.sh` — login → (optional OTP) → action in one command

Orchestrates the others. PlaceCal's Devise login uses **nested** params, and
`flow.sh`'s `--email`/`--password` flags assume flat params — so for PlaceCal,
prefer `submit_form.rb` for login (above), or drive `flow.sh` via
`--login-fields` with the nested names:

```
flow.sh --email admin@example.com --login-path /users/sign_in \
        --login-fields 'user[email]=admin@example.com&user[password]=password' \
        --then-path / --then-method GET
```

`flow.sh`'s OTP machinery (read a one-time code from the dev log) is here for the
day PlaceCal grows a passwordless/magic-link flow; it isn't used by Devise
password login today.

### `scripts/jar_to_storage.rb` / `scripts/storage_to_jar.rb` — Playwright bridge

Convert the curl session jar to Playwright `storageState` JSON and back, so you
log in once and share the session with a Playwright MCP for JS-dependent checks
curl can't make. The bridge is MCP-agnostic — it just emits the standard
`storageState` format, so any Playwright MCP works (the official `@playwright/mcp`
or whichever you have connected). For most PlaceCal work you won't need this:
**Claude in Chrome** is the standard for `lvh.me`; reach for Playwright only when
you specifically want a scripted/headless browser.

```
ruby .../jar_to_storage.rb --origin http://admin.lvh.me:3000 > state.json   # curl -> PW
ruby .../storage_to_jar.rb --in state.json                                  # PW  -> curl
```

## The verify loop (this is the point)

1. **Log in once** with `submit_form.rb` against `/users/sign_in`.
2. **Fast server-side assertions with curl**: the action redirected where
   expected, the turbo-stream targeted the right element, the expected SQL ran,
   nothing errored — `readlog.sh request <id>` gives a clean single-request
   slice of the log.
3. **Only for JS-dependent behaviour**, verify in **Claude in Chrome** (the
   `lvh.me` standard) — did Stimulus wire up, did the frame load, did the DOM
   actually mutate. If you need a scripted browser instead, bridge the session
   (`jar_to_storage.rb`) into a Playwright MCP.

This keeps Claude verifying its own work end-to-end instead of claiming a fix
worked — most checks are fast curl + log; the browser is only for the residual
JS bits.

## Guardrails (don't weaken these)

- **Local only.** Both shell scripts and `submit_form.rb` reject non-local hosts
  (`localhost`, `*.localhost`, `lvh.me`, `*.lvh.me`). Keep it that way.
- **No production logs.** `readlog.sh` refuses paths containing `production`.
- **Don't echo cookies.** `req.sh` redacts `Set-Cookie`; report auth state, not
  the session value.

## Config (env vars)

- `BASE_URL` — `http://lvh.me:3000` (public) or `http://admin.lvh.me:3000` (admin).
- `JAR` — cookie jar path, default `./.hotwire/cookies.txt`.
- `LOG_FILE` — default `./log/development.log`.
- `MAX_BYTES` — response body cap for `req.sh`, default `100000`.
- `RUBY` — how to run the Ruby scripts, default `bundle exec ruby`.
