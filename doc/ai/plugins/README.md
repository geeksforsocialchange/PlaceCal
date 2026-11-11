# AI assistant plugins

Vendored, PlaceCal-adapted Claude Code plugins (an agent + a skill). These are the
"active" half of PlaceCal's AI tooling: the prompt files in `doc/ai/prompts/` and
`AGENTS.md` give an assistant _context_; these give it _capabilities_ it can
invoke on demand.

They are kept here — tool-agnostic markdown + scripts in the tracked repo — so the
team shares one source of truth. `.claude/` itself stays gitignored (personal);
**`bin/setup-ai` symlinks these into your local `.claude/`** so Claude Code picks
them up. Edit the files here, not the symlinks; re-run `bin/setup-ai` if links go
stale.

## What's here

| Plugin                 | Type  | What it does                                                                                                                                                                                                                                                                   | When it triggers                                         |
| ---------------------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| `rails-hotwire-driver` | skill | Drive the running dev server from the terminal — log in via Devise, submit forms (CSRF handled), inspect Turbo Streams, read `development.log` by request id. The runtime half of the **verify loop**.                                                                         | Verifying a server-rendered change actually works        |
| `judge-arch`           | skill | Fresh-context architectural review of a diff against the four questions (boundary placement, data ownership, dependency direction, error handling) and PlaceCal's own layer rules, with a grep-test for web concerns leaking into domain code. Findings only, PASS when clean. | Before calling a non-trivial change done or opening a PR |
| `better-stimulus`      | agent | Opinionated StimulusJS best practices (Values API, mixins, late binding, Turbo teardown), adapted to PlaceCal's native-JS / importmap / `controllers/mixins/` setup.                                                                                                           | Writing, reviewing, or debugging a Stimulus controller   |

## Provenance

Adapted from [`maquina-app/rails-claude-code`](https://github.com/maquina-app/rails-claude-code)
by Mario Alberto Chávez Cárdenas, MIT-licensed (see `LICENSE.txt`). We vendor
(rather than install from the marketplace) deliberately: it removes the
solo-maintainer / upstream-churn risk and lets us adapt each plugin to PlaceCal's
stack (Phlex, RSpec, Devise, Pundit, `lvh.me`, importmap). Upstream has more
plugins (`rails-simplifier`, `rails-security-auditor`, `maquina-ui-standards`,
`mvp-creator`, `recuerd0`, etc.); we skipped them because they assume a different
stack (ERB/minitest/`maquina_components`/service-object-free) or duplicate tooling
we already have. Notably we skipped `rails-security-auditor` because Brakeman
(CI-gated), Dependabot, and our existing GraphQL depth/complexity limits already
cover that ground, and `rails-simplifier` because its safe rules duplicate
`/code-review` + `/simplify` while its opinionated refactors fight a mature
codebase.

`judge-arch` is adapted from Tech Fleet's
[enterprise-software-AI-skills](https://github.com/techfleetworks/enterprise-software-AI-skills)
(MIT). We took the review rubric and the fresh-context stance and rewrote the
examples for Rails/Phlex; the mechanical gate script and its React/Supabase
presets were left out because Brakeman, RuboCop, `strong_migrations` and the
skill's grep-test already cover PlaceCal's layer rules. The rest of that
collection (OWASP, test pyramid, ADRs, release safety, SRE, compliance, WCAG,
browser support, usability) restates things PlaceCal already enforces
specifically, so it was not adopted; the vendoring PR maps each one to where
we already do it.

## Install

```bash
bin/setup-ai      # symlinks these plugins into ./.claude/{agents,skills}
```

## The verify loop

`rails-hotwire-driver` exists to make Claude verify its own work instead of
claiming a fix worked (per `CLAUDE.md`). Fast server-side assertions go through
curl + log reading; JS-dependent checks (Stimulus, DOM, maps) go through **Claude
in Chrome** (our standard for `lvh.me`, per `CLAUDE.md`), or optionally a
Playwright MCP via the session bridge so you log in once. See
`rails-hotwire-driver/SKILL.md`.
