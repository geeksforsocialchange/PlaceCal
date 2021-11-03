#!/bin/bash

# Env Vars Expected:
# SSH_PRIVATE_KEY  -  Private deployment key
# DOKKU_HOST       -  Domain name for deployment (placecal.com/etc.)
# GITHUB_WORKSPACE -  Repository root directory (Automagically set by GitHub)
# TARGET_REPO      -  Name of repo on dokku's side (placecal-staging/etc.)
# TARGET_BRANCH    -  Name of the branch on dokku's side (main)
# SOURCE_BRANCH    -  Name of the source branch to deploy from (main/production)

TARGET_BRANCH="main"

# Create the appropriate directory
mkdir -p ~/.ssh
# Start the ssh agent
eval "$(ssh-agent -s)"
# Install the SSH key on the workflow server temporarily
echo "$SSH_PRIVATE_KEY" | ssh-add -
# Ensure Dokku is listed as a known host (Solve asking for fingerprint)
ssh-keyscan "$DOKKU_HOST" >> ~/.ssh/known_hosts
# Change directory to the repo
cd "$GITHUB_WORKSPACE"
# Add remote to git
git remote add deploy "dokku@$DOKKU_HOST:$TARGET_REPO"
# Simple push default (?)
git config --global push.default simple

# Set a nice lil ssh command for Git to use
# The github action idoberko2/dokku-deploy-github-action@v1 does this, but also everything above
# Kind of strange to provide a known hosts file and then set ssh's known hosts file to the bit bucket?
# export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

# Deploy
git push --force deploy "$SOURCE_BRANCH:$TARGET_BRANCH"
