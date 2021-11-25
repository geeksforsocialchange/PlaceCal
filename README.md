# PlaceCal

## Introduction / Warning

PlaceCal is a large and very complicated app for collating organisation and event information from a large variety of sources. In the words of one developer: "I'm not sure where the interface between the app and the real world is here".

To get an idea of the project and what we're about, check out [the handbook](https://handbook.placecal.org/) which is also [in it's own respository](https://github.com/geeksforsocialchange/PlaceCal-Handbook), and especially the [Glossary](glossary.md).

## Quickstart

With that said, here's what you need to get rolling.

* postgresql, Ruby as specified in `.ruby-version`, and the Bundler gem to install rails 5 etc from the Gemfile
* `bundle exec rails db:setup db:migrate seed:migrate`
* `bundle exec rails import:all_events`
* Make sure you use `lvh.me:3000` instead of `localhost` or you might have authentication problems.
* Admin interface is `admin.lvh.me:3000`
* Seeded root user is info@placecal.org / password
* Access code docs through your local filesystem, and update with `bundle exec rails yard`

To set up your own server, take a look at `INSTALL.md`.

## Roadmap

See the current [Roadmap](developers/roadmap.md)
