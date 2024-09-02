# Releasing PlaceCal

## 1. Validate changes since the [last release](https://github.com/geeksforsocialchange/PlaceCal/releases)

Every pull request gets added to the latest draft release automatically. Validate them on the staging server before continuing.

1. Validate that each pull request in the draft release does what it's meant to:
   1. If it's a bug fix, check the bug linked in the PR is fixed on the [staging server](https://placecal-staging.org/). If it is, add a screenshot in a comment on the bug's issue ticket so the original reporter gets notified a fix is on the way.
   2. If it's a new feature, make a screenshot or video of the feature working on the staging server and add it as a comment in the pull release.
2. In both cases, open new issues as needed if these don't resolve the issue.
3. If you're happy to proceed, continue to the next step. If not, merge PRs to address issues until you are.
4. Decide the next version number [by reviewing the current one](https://github.com/geeksforsocialchange/PlaceCal/releases)

## 2. Deploy to production

1. [Open a pull request from `main` into `production`](https://github.com/geeksforsocialchange/PlaceCal/compare/production...main)
2. Title it with the next version number.
3. Ensure you are doing a **merge commit based merge**. Do not squash or rebase, and wait for CI to pass.
4. **Do not update the branch using the automatically generated prompt**. Github will invite you to update the branch because `production` has additional merge commits that don't exist in `main`. It's no big deal if you forget, but this just creates an unneeded extra commit that needs merging back into `main` later.
5. Get someone to approve the PR, then merge into production.
6. Once the CI passes on the `production` branch, the patch is live. You can double check the git reference in the admin interface on the left sidebar to check this has happened.

## 3. Make a release

Assuming everything is working, create a new release.

1. [Edit the draft release](https://github.com/geeksforsocialchange/PlaceCal/releases)
2. Give it a version number and nice description of what's changed. Refer to previous releases to get an idea how to write these. Match the release title to a tag with the same version number.
3. Press the "Publish" button on the release.
4. Email releases@lists.placecal.org with the patch notes.

Well done! You released a new version of PlaceCal.
