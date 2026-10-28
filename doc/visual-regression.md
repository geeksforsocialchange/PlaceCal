# Visual Regression Testing

Theme CSS (core colour themes and extension themes such as The Trans Dimension and Mossley) styles core markup, so a change to a core component can break a themed site without touching the theme. `bin/visual-regression` screenshots public pages under every installed theme, in Chromium and WebKit, for a base commit and your working tree, and diffs them.

## Prerequisites

- [ImageMagick](https://imagemagick.org/): `brew install imagemagick`
- Playwright browsers: `yarn install && yarn playwright install chromium webkit`
- A local PostgreSQL that `bin/rails db:create` can use

## Usage

```bash
bin/visual-regression                     # compare against the merge base with main
bin/visual-regression --base origin/main  # any branch, remote branch, SHA or HEAD
bin/visual-regression --fresh             # recapture the cached baseline
bin/visual-regression clean               # remove screenshots and cached baselines
```

A bare branch name prefers its remote-tracking branch from whichever remote has it. The script:

1. Finds the merge base of `HEAD` and the base ref.
2. Captures the base in a temporary `git worktree` (your working tree is never stashed or checked out): copies the current screenshot harness in, installs gems, runs `yarn build`, loads the schema into its own `_base` database and captures. The worktree and database are removed on exit. Baselines are cached per base SHA and harness version.
3. Builds assets and captures your working tree, including uncommitted changes.
4. Compares each pair, padding shorter screenshots with magenta so extra height counts as changed, and writes `tmp/visual_regression/summary.md`.

It exits non-zero only when capture fails. A full run with a fresh baseline takes about two and a half minutes on a recent Mac; with a cached baseline, about one and a half.

Environment variables: `VR_BROWSERS` (default `chromium webkit`), `VR_WIDTHS` (viewport widths in px, default `450 950 1250`), `VR_DATABASE_URL` (default `postgres:///placecal_vr`), `VR_FUZZ` (per-channel tolerance before a pixel counts as changed, default `1%`), `VR_JOBS` (parallel comparisons, default 4), `VR_NOISE_PIXELS` (a diff of this many pixels or fewer, with no height change, is listed separately as likely anti-aliasing rather than counted as a change, default 250).

## Output

`tmp/visual_regression/` holds `base/<sha>-<harness>/<browser>/`, `current/<browser>/`, `diff/<browser>/` (changed pixels in red), `results.tsv` and `summary.md`. Files are named `<theme>__<page>__<width>.png`, for example `transdimension__events__450.png`.

## What it covers

- **Themes**: core `pink` plus every installed extension theme (`PlaceCal::Extensions.themes`), so a newly installed theme is picked up automatically.
- **Site pages** under each theme: home, events, event, partners, partner, news, article, and every page the theme registers with `theme.page`.
- **Core only**: the directory homepage and the join homepage.
- **Widths**: 450, 950 and 1250px, full page.

Screenshots are deterministic: the database is truncated and Faker seeded before the Normal Island data is built, server and browser clocks are frozen to 8 November 2022, captures wait for webfonts and images, animations and the caret are disabled, and map contents are hidden (their space is kept). Theme webfonts loaded from third parties (Typekit for The Trans Dimension) still come from the network.

## CI

`.github/workflows/visual-regression.yml` runs on pull requests that touch components, views, stylesheets, Tailwind, `config/initializers/extensions.rb` or `Gemfile.lock`, and on demand. It uploads the screenshots as the `visual-regression` artifact and keeps one PR comment updated with the summary. It does not block merging. Linux and macOS render fonts differently, so compare screenshots only with others from the same machine.

## Running the spec directly

```bash
VISUAL_REGRESSION=1 bundle exec rspec spec/system/visual_regression_spec.rb --order defined
```

Screenshots go to `tmp/visual_regression/current/` (or `VR_OUTPUT_DIR`).

## Adding pages

Add an entry to `SITE_PAGES` (captured under every theme) or `APEX_PAGES` (captured once) in `spec/support/visual_regression.rb`. Each maps a name to a lambda returning the path, evaluated in the example so it can use the Normal Island data.
