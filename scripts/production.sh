eval "$(ssh-agent -s)" #start the ssh agent
chmod 600 production-deploy.key # this key should have push access
ssh-add production-deploy.key
ssh-keyscan placecal.org >> ~/.ssh/known_hosts
git remote add deploy dokku@placecal.org:placecal
git config --global push.default simple
git push deploy production
