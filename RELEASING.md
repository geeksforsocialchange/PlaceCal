# Releasing PlaceCal

## 1. Review the [draft release](https://github.com/geeksforsocialchange/PlaceCal/releases)

Every pull request gets added to the latest draft release automatically by robots.

Go through each one and test any related tickets are truly fixed on the staging site and the new behaviour works as described. If there are any issues, make a call as to whether they need resolving before the release can happen or not. If they're not blocking issues, reopen the tickets or open new tickets for them instead and continue with the release.

## 2. Open a pull request

If everything looks good to publish, open a pull request from `main` into `production` and give it a title reflecting the new version we're releasing.

Github will invite you to update the branch because `production` has aditional merge commits that don't exist in `main`, you don't need to do this.

## 3. Edit the release

Edit the draft release to reflect the reality of what we're releasing after reviewing for any unresolved issues. The main aim here is to avoid misleading our future selves with "Fixed X" items when we actually didn't. **Importantly, don't remove any PR links.** Even if the thing they related to didn't work, we want the reference there to know what's included.

Set the release up to create a new tag of the head of the `main` branch on publish and set the release title to match.

## 4. Merge the pull request

Do a **merge commit based merge**. Do not squash or rebase! And wait for CI!

## 5. Publish the release

Press the "publish" button on the release.

## 6. Check the release

Check to make sure the release went to plan and everything works as expected.
