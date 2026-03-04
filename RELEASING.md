# Releasing PlaceCal

PlaceCal uses **Kamal 2** for deployments. Pushes to `main` auto-deploy to staging. Publishing a GitHub release deploys to production.

## 1. Validate changes on staging

Every pull request merged to `main` is automatically deployed to [placecal-staging.org](https://placecal-staging.org/) and added to the draft release by [release-drafter](https://github.com/release-drafter/release-drafter).

1. For each PR in the [draft release](https://github.com/geeksforsocialchange/PlaceCal/releases):
   - **Bug fix**: Check the bug is fixed on staging. Screenshot it and comment on the issue.
   - **New feature**: Screenshot/video the feature on staging and comment on the PR.
2. Open new issues for anything that doesn't look right.
3. Add the `verified` label to resolved issues.

## 2. Deploy to production

1. [Edit the draft release](https://github.com/geeksforsocialchange/PlaceCal/releases).
2. Set the version number as the tag (e.g. `v1.2.3`). Refer to previous releases for numbering.
3. Write a description of what's changed.
4. Press **Publish release** — this triggers the production deploy via GitHub Actions.

## 3. Verify the deploy

```sh
# Check the deploy completed successfully
kamal app details -d production

# Check the running version
kamal app version -d production
```

You can also check the git reference in the admin sidebar on [placecal.org](https://placecal.org/).

## 4. Rollback (if needed)

```sh
# Roll back to the previous version
kamal rollback -d production

# Or deploy a specific version
kamal rollback <version> -d production
```

## 5. Notify

Email [releases@lists.placecal.org](mailto:releases@lists.placecal.org) with the release notes.

## Manual deploys

For ad-hoc deploys (e.g. hotfixes), use the [workflow_dispatch trigger](https://github.com/geeksforsocialchange/PlaceCal/actions/workflows/test-and-deploy.yml) or deploy from your local machine:

```sh
kamal deploy -d staging    # or -d production
```
