# PlaceCal

[![Build Status](https://travis-ci.org/geeksforsocialchange/PlaceCal.svg?branch=master)](https://travis-ci.org/geeksforsocialchange/PlaceCal) [![Maintainability](https://api.codeclimate.com/v1/badges/18174238dc53c658212b/maintainability)](https://codeclimate.com/github/geeksforsocialchange/PlaceCal/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/18174238dc53c658212b/test_coverage)](https://codeclimate.com/github/geeksforsocialchange/PlaceCal/test_coverage)

## Introduction / Warning

PlaceCal is a large and very complicated app for collating organisation and event information from a large variety of sources. In the words of one developer: "I'm not sure where the interface between the app and the real world is here".

To get an idea of the project and what we're about, check out [the handbook](https://handbook.placecal.org/) which is also [in it's own respository](https://github.com/geeksforsocialchange/PlaceCal-Handbook), and especially the [Glossary](glossary.md).

## Quickstart

With that said, here's what you need to get rolling.

* Rails 5 / Ruby 2.4 / postgresql
* `rails db:setup db:migrate seed:migrate`
* `rails import:all_events`
* Make sure you use `lvh.me:3000` instead of `localhost` or you might have authentication problems.
* Admin interface is `admin.lvh.me:3000`
* Seeded root user is info@placecal.org / password

To set up your own server, take a look at `INSTALL.md`.

## Roadmap

See the current [Roadmap](developers/roadmap.md)
