# PlaceCal

## Introduction / Warning

PlaceCal is a large and very complicated app for collating organisation and event information from a large variety of sources. In the words of one developer: "I'm not sure where the interface between the app and the real world is here".

To get an idea of the project and what we're about, check out [the handbook](https://handbook.placecal.org/) which is also [in it's own respository](https://github.com/geeksforsocialchange/PlaceCal-Handbook), and especially the [Glossary](glossary.md).

## Requirements

To run Placecal locally you will need:

- a mac or a linux machine
- gcc
- postgres 
  - if you are running in a docker image you will still need the dev libraries for the gem to compile against
- base ruby for your OS
- [rbenv](https://github.com/rbenv/rbenv)
  - [ruby-build](https://github.com/rbenv/ruby-build)
  - [rbenv-gemset](https://github.com/jf/rbenv-gemset) (optional)
- ImageMagick
- docker (optional)
  If you are into containerizing your dev environment

## Quickstart

With that said, here's what you need to get rolling.

```
git clone https://github.com/geeksforsocialchange/PlaceCal.git
bundle && yarn
bundle exec rails db:setup db:migrate seed:migrate
bundle exec rails import:all_events
bundle exec rails server
```

* Make sure you use `lvh.me:3000` instead of `localhost` or you might have authentication problems.
* Admin interface is `admin.lvh.me:3000`
* Seeded root user is info@placecal.org / password
* Access code docs through your local filesystem, and update with `bundle exec rails yard`

To set up your own server, take a look at `INSTALL.md`.

## Contributing

We welcome new contributors but strongly recommend you have a chat with us in [Geeks for Social Change's Discord server](http://discord.gfsc.studio) and say hi before you do. We will be happy to onboard you properly before you get stuck in.

## Donations

If you'd like to support development, please consider sending us a one-off or regular donation on Ko-fi.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/M4M43THUM)
