eval "$(ssh-agent -s)" #start the ssh agent
chmod 600 .travis/deploy.key # this key should have push access
ssh-add .travis/deploy.key
ssh-keyscan placecal-staging.org >> ~/.ssh/known_hosts
git remote add deploy dokku@placecal-staging.org:placecal-staging
git config --global push.default simple
git push deploy master
