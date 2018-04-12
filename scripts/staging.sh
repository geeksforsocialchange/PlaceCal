eval "$(ssh-agent -s)" #start the ssh agent
echo $PWD
ls -a
chmod 600 $TRAVIS_BUILD_DIR/deploy.key # this key should have push access
ssh-add $TRAVIS_BUILD_DIR/deploy.key
ssh-keyscan placecal-staging.org >> ~/.ssh/known_hosts
git remote add deploy dokku@placecal-staging.org:placecal-staging
git config --global push.default simple
git push deploy master
