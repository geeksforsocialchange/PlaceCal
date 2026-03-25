# Visual Regression Testing

Compare screenshots of every public page before and after CSS changes to catch unintended layout breakages.

## Prerequisites

- [ImageMagick](https://imagemagick.org/) for generating diff images: `brew install imagemagick`

## Usage

From your feature branch:

```bash
bin/visual-regression                              # compare against main (default)
bin/visual-regression --base refactor/my-branch    # compare against a specific branch
```

This does everything in one command:

1. Resolves the HEAD SHA of the base branch (default: `main`)
2. If no cached baseline exists for that SHA, temporarily checks out the base branch, captures screenshots, then restores your branch
3. Captures screenshots on your current branch
4. Diffs the two sets with ImageMagick (5% fuzz to ignore anti-aliasing)
5. Reports which pages changed

### Output

```
=== Visual Regression Test ===
Base:   main (ea8cc003)
Branch: feature/tailwind-migration

Baseline: using cached (56 screenshots for ea8cc003)

Current branch: capturing screenshots...
  Captured 56 screenshots

Comparing...
  CHANGED: home_desktop.png (12453 pixels)
  CHANGED: home_mobile.png (8921 pixels)

Results: 2 changed, 54 unchanged, 0 missing
Diff images in tmp/visual_regression/diff/ (red pixels = layout differences)
```

Diff images are saved to `tmp/visual_regression/diff/`. Red pixels show where layouts differ. Open them with Preview or any image viewer.

### Cached baselines

Baselines are cached in `tmp/visual_regression/baselines/{sha}/`. They're reused until main moves forward, so the first run takes ~70 seconds but subsequent runs take ~35 seconds.

To clear the cache (e.g. after rebasing):

```bash
bin/visual-regression clean
```

## What it covers

14 pages at 4 viewports (450px, 650px, 950px, 1250px) = 56 screenshots:

- **Static pages**: homepage, find-placecal, our-story, privacy, terms-of-use, get-in-touch
- **Events**: index, show
- **Partners**: index, show
- **News**: index, show
- **Collections**: show
- **Partner-themed site**: homepage (subdomain routing)

## Running the spec directly

```bash
VISUAL_REGRESSION=1 bundle exec rspec spec/system/visual_regression_spec.rb --order defined
```

The `VISUAL_REGRESSION=1` env var is needed because the spec is excluded from the normal test suite by default. Screenshots are saved to `tmp/screenshots/`. Use `--order defined` to ensure deterministic output.

## Adding pages

Edit `spec/system/visual_regression_spec.rb`. Each page is a separate RSpec example — add a new `it` block, visit the page, and call `screenshot_page("name")`.
