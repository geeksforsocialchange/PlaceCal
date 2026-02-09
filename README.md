# PlaceCal

## Introduction

PlaceCal is an online calendar which lists events and activities by and for members of local communities, curated around interests and locality.

The codebase has seeds that create a full development environment with fictional data (see [Seeds](#seeds) below).

To get an idea of the project and what we're about, check out [the handbook](https://handbook.placecal.org/).

## Requirements

To run PlaceCal locally you will need to install the following dependencies:

- [Docker](https://docs.docker.com/get-docker/)
- [Ruby 3.3.x](https://www.ruby-lang.org/)
- [Node.js 20.x](https://nodejs.org/en/download) & (optional) [nvm](https://github.com/nvm-sh/nvm) to manage it
- [Yarn 1.x](https://classic.yarnpkg.com/lang/en/)
- [ImageMagick](https://imagemagick.org/index.php) for image manipulation
- [Graphviz](https://voormedia.github.io/rails-erd/install.html) for documentation diagrams
- [Chrome/Chromium](https://www.chromium.org/chromium-projects/) for system tests along with a matching version of [Chromedriver](https://chromedriver.chromium.org/)

## Quickstart with docker for GFSC devs

Make sure all of the above dependencies are installed (and ask someone to add your public ssh key to the servers if you are staff).

Then make sure the docker daemon is running, and run

```sh
make setup_with_docker
```

Local site is now running at `lvh.me:3000`

Some other useful commands for developing can be found in the makefile.

## Troubleshooting

If the make command fails and you can't work out why, here are some suggestions:

- Do you have an older version of the database hanging around? Try running `rails db:drop:all`
- Is the docker daemon running?
- Is the port in use by another application or docker container? Try stopping or removing any conflicting containers
- Are you using the correct node version? Try running `nvm use`

## Quickstart for everyone else

### Set up Postgresql locally with docker

If you don't already have Postgresql installed and running, you can set it up with docker, just run `make docker`. To tear down the docker setup, run `make clean`.

### Run the setup script

```sh
bin/setup
```

Amongst other things, this will create seed users for you. All passwords are `password`.

- **Root admin**: `root@placecal.org` — full access to everything

### Run the thing

- Start the server with `bin/dev`
- Make sure you use `lvh.me:3000` instead of `localhost:3000` or you **will** have authentication problems
- The admin interface is at `admin.lvh.me:3000`
- Access code docs through your local filesystem and update them with `bin/rails yard`

### Importing calendars

To import all events, run the following command.

```sh
rails events:import_all_calendars
```

After this has run once, the following command can be run which attempts to skip calendars which have not been updated. This should be run regularly on a cron in production environments. If you are using dokku to deploy like we are, this is handled in the `app.json` config file.

```sh
rails events:scan_for_calendars_needing_import
```

To import one calendar, run:

```sh
rails events:import_calendar[100]

# nb: zsh users will need to escape brackets
rails events:import_calendar\[100\]
```

## Testing, linting and formatting

PlaceCal uses **RSpec** for unit/integration tests and **Cucumber** for BDD-style acceptance tests. We use Rubocop to lint our Ruby code.

We use [Prettier](https://prettier.io/) to format everything it's able to parse. We run this automatically as part of a pre-commit hook.

**Note:** Tests require a running PostgreSQL database. If using Docker, ensure `make docker` is running first.

### Running tests

```sh
# All tests with linting
make test

# Fast unit tests only (excludes system specs)
bin/test --unit --no-lint

# System tests (browser-based, requires Chrome)
bin/test --system --no-lint

# Cucumber features
bin/test --cucumber --no-lint

# Direct commands
bundle exec rspec                        # Fast specs only
RUN_SLOW_TESTS=true bundle exec rspec    # Include system specs
bundle exec cucumber                     # Cucumber features
```

### Test data: Normal Island

Tests and seeds use a fictional geography called "Normal Island" (country code: ZZ, a user-assigned ISO 3166 code) to avoid conflicts with real UK data. See `lib/normal_island.rb` for the full data structure and `doc/testing-guide.md` for guidance on writing tests.

## Seeds

Running `bin/setup` or `bin/rails db:seed` populates the database with realistic development data using the Normal Island fictional geography. Seeds are **idempotent** (safe to re-run) and **additive** (layer alongside existing data, e.g. after cloning a production database).

### What gets created

- **Neighbourhoods**: Full Normal Island hierarchy (country, 2 regions, 2 counties, 3 districts, 8 wards)
- **Tags**: 5 categories, 4 facilities, 3 partnerships
- **Sites**: 4 published sites — 3 at different geographic levels (country, county, district) and 1 partnership site (Normal Island Book Clubs) — each with hero images, logos, and themes. Plus one unpublished default site.
- **Users**: 9 users covering every admin role, with avatars (see table below). All passwords are `password`.
- **Partners**: ~100 partners across all 8 wards, each with address, categories, social media links, opening times, phone numbers, and images
- **Events**: 600+ events per partner (mix of past and future dates) with 50 different event types

### Seed users

| Email                                 | Role                | Scope                   |
| ------------------------------------- | ------------------- | ----------------------- |
| root@placecal.org                     | Root                | Everything              |
| editor@placecal.org                   | Editor              | All news articles       |
| neighbourhood-admin@placecal.org      | Neighbourhood admin | Millbrook district      |
| partner-admin@placecal.org            | Partner admin       | Riverside Community Hub |
| site-admin-normal-island@placecal.org | Site admin          | Normal Island site      |
| site-admin-coastshire@placecal.org    | Site admin          | Coastshire site         |
| site-admin-millbrook@placecal.org     | Site admin          | Millbrook site          |
| site-admin-book-clubs@placecal.org    | Site admin          | Book Clubs site         |
| citizen@placecal.org                  | Citizen             | No admin access         |

### Geocoding

Seeds use a custom geocoder lookup (`Geocoder::Lookup::NormalIsland`) that handles Normal Island's ZZ-prefix postcodes locally without hitting any external API. Real UK postcodes are delegated to postcodes.io as normal. This lookup is active in all environments.

### Sites in development

After seeding, these sites are available:

| Site                     | URL                              | Type        |
| ------------------------ | -------------------------------- | ----------- |
| Normal Island            | http://normal-island.lvh.me:3000 | Country     |
| Coastshire               | http://coastshire.lvh.me:3000    | County      |
| Millbrook                | http://millbrook.lvh.me:3000     | District    |
| Normal Island Book Clubs | http://book-clubs.lvh.me:3000    | Partnership |
| Admin                    | http://admin.lvh.me:3000         | —           |

## Documentation

Further documentation for PlaceCal is in the [PlaceCal Handbook](https://handbook.placecal.org/).

The developer Procfile will load a `yard` language server, this is visible at `http://localhost:8808`.

If you are working with the code and are completely lost you can also try the [GFSC discord server](http://discord.gfsc.studio) where you can prod a human for answers.

### Generating new components

We use view_component to make components, and you can create a new one by running `rails g component <Name> <args>`
Previously this system used mountain view, and some of the components are still generated using this.

More info here: https://viewcomponent.org/guide/generators.html

### Folder structure

Our project is showing it's age and migration across multiple Rails version. Here's the state of play at the moment - we are currently aiming to simplify this and remove deprecated files.

```
── app
│   ├── assets
│   │   ├── builds              # Bundled JavaScript
│   │   ├── config              # Specifies assets to be compiled
│   │   ├── fonts
│   │   ├── images
│   │   └── stylesheets
│   ├── components              # ViewComponent components for reusable UI elements
│   ├── constraints             # Directs to correct site based on subdomain
│   ├── controllers             # Public app controllers
│   │   ├── admin               # Admin area controllers
│   │   ├── concerns
│   │   └── users
│   ├── datatables              # Admin area datatables
│   ├── graphql                 # API
│   ├── helpers
│   ├── javascript              # Source JavaScript
│   │   ├── controllers
│   │   └── src
│   ├── jobs                    # Importer logic - jobs are created by cron (`/lib/tasks`). There's a readme here with more info
│   ├── mailers                 # Email configuration
│   ├── models
│   ├── policies                # Pundit rules for who can do and access what
│   ├── uploaders               # CarrierWave rules for handling image and logo uploads
│   ├── validators              # Postcode validator - should possibly live somewhere else, or have other validators moved in here
│   └── views
│       ├── admin               # Admin area
│       ├── collections         # Deprecated feature to create abritrary event collections, was previously used for our early winter festivals
│       ├── devise              # Authentication
│       ├── events              # Event indexes and show page
│       ├── join_mailer         # Templates for creating accounts
│       ├── joins               # "Join PlaceCal" form page
│       ├── layouts             # Page templates
│       ├── moderation_mailer   # Templates for when partners get moderated
│       ├── news                # News article templates - half implemented
│       ├── pages               # Static pages mostly used on homepage. Some pages here are not linked anywhere currently
│       ├── partners            # Partner indexes and show pages
│       ├── shared              # Some shared elements - should probably be migrated to view_components
│       └── sites               # Site homepages e.g. mysite.placecal.org
├── collections                 # API examples to be loaded with Bruno
├── config
│   ├── environments
│   ├── initializers
│   ├── locales
│   └── robots
├── db
│   ├── images                  # Some seed images - not been looked at for a while
│   │   ├── sites
│   │   └── supporters
│   ├── migrate
│   └── seeds                   # Seeds using Normal Island data for development
├── doc                         # Documentation including testing guides and ADRs
│   ├── adr                     # Architectural decision records
│   ├── ai                      # Optional AI coding assistant configuration
│   └── testing-guide.md        # Guide for writing tests with Normal Island data
├── features                    # Cucumber BDD features
│   ├── step_definitions        # Step implementations
│   └── support                 # Cucumber environment setup
├── lib
│   ├── assets
│   ├── data                    # UK geography ward to district data used to create neighbourhood info
│   ├── normal_island.rb        # Fictional geography data for tests and seeds
│   ├── tasks                   # Rake tasks that create ActiveJobs
│   └── templates
│       └── erb                 # Rails scaffold templates
├── log
├── nginx.conf.d                # Config files here get added to the nginx config by dokku
├── public
├── scripts
├── spec                        # RSpec test suite
│   ├── components              # ViewComponent specs
│   ├── factories               # FactoryBot factories using Normal Island data
│   │   └── normal_island       # Normal Island-specific factories
│   ├── fixtures
│   │   └── vcr_cassettes       # Recorded API responses for testing
│   ├── helpers                 # Helper specs
│   ├── jobs                    # Background job specs (calendar importers)
│   ├── mailers                 # Mailer specs
│   ├── models                  # Model specs
│   ├── policies                # Pundit policy specs
│   ├── requests                # Request specs (controllers, GraphQL)
│   │   ├── admin
│   │   ├── graphql
│   │   └── public
│   ├── support                 # Test helpers, shared contexts/examples
│   └── system                  # Capybara system specs (requires Chrome)
│       └── admin
```

## API

API examples and test environment are provided using [Bruno](https://www.usebruno.com/).

Install it with your system package manager then point it at the `collections` directory.

## AI Coding Assistants (Optional)

PlaceCal includes optional support for AI coding assistants. We're tool-agnostic and have structured the project to work with various AI assistants.

**Note:** This is a legacy codebase with significant tech debt. AI assistants can help navigate and improve it, but expect some rough edges.

### Setup

```sh
bin/setup-ai
```

This enables the optional `:ai` gem group and installs dependencies.

### What's Included

- `AGENTS.md` - Context file for AI assistants
- `doc/ai/` - Agent configuration and prompts
- `agents-swarm.yml` - Multi-agent swarm configuration

### Using with Different Tools

The configuration is designed to be adaptable:

- **Claude Code / Cursor**: Uses `AGENTS.md` for context automatically
- **Other assistants**: Point them at `AGENTS.md` and `doc/ai/context.md`
- **Swarm-based tools**: Use `agents-swarm.yml` for multi-agent setups

### Disabling

```sh
bundle config unset --local with
bundle install
```

## Donations

If you'd like to support development, please consider [supporting GFSC](https://gfsc.community/support-us/).
