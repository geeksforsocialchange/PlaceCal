# PlaceCal

## Introduction

PlaceCal is an online calendar which lists events and activities by and for members of local communities, curated around interests and locality.

The codebase doesn't currently have enough seeds to create a dev environment suitable for developing from scratch. If you're interested in contributing to PlaceCal please get in touch at support@placecal.org

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

Amongst other things, this will create an admin user for you:

- Username: `info@placecal.org`
- Password: `password`

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

PlaceCal tests are written in minitest. We use Rubocop to lint our Ruby code.

We use [Prettier](https://prettier.io/) to format everything it's able to parse. We run this automatically as part of a pre-commit hook.

You can run the tests & rubocop with:

```sh
make test
```

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
│   ├── assets
│   │   ├── builds              # Bundled JavaScript
│   │   ├── config              # Specifies assets to be compiled
│   │   ├── fonts
│   │   ├── images
│   │   └── stylesheets
│   ├── components              # A mix of mountain_view and view_component components (the latter have the `_component` suffix).
│   ├── constraints             # Directs to correct site based on subdomain
│   ├── controllers             # Public app controllers
│   │   ├── admin               # Admin area controllers
│   │   ├── concerns
│   │   └── users
│   ├── datatables              # Admin area datatables
│   ├── graphql                 # API
│   ├── helpers
│   ├── javascript              # Source JavaScript
│   │   ├── controllers
│   │   └── src
│   ├── jobs                    # Importer logic - jobs are created by cron (`/lib/tasks`). There's a readme here with more info
│   ├── mailers                 # Email configuration
│   ├── models
│   ├── policies                # Pundit rules for who can do and access what
│   ├── uploaders               # CarrierWave rules for handling image and logo uploads
│   ├── validators              # Postcode validator - should possibly live somewhere else, or have other validators moved in here
│   └── views
│       ├── admin               # Admin area
│       ├── collections         # Deprecated feature to create abritrary event collections, was previously used for our early winter festivals
│       ├── devise              # Authentication
│       ├── events              # Event indexes and show page
│       ├── join_mailer         # Templates for creating accounts
│       ├── joins               # "Join PlaceCal" form page
│       ├── layouts             # Page templates
│       ├── moderation_mailer   # Templates for when partners get moderated
│       ├── mountain_view       # Deprecated - views for the mountain_view stylesheet page showing all the components
│       ├── news                # News article templates - half implemented
│       ├── pages               # Static pages mostly used on homepage. Some pages here are not linked anywhere currently
│       ├── partners            # Partner indexes and show pages
│       ├── shared              # Some shared elements - should probably be migrated to view_components
│       └── sites               # Site homepages e.g. mysite.placecal.org
├── collections                 # API examples to be loaded with Bruno
├── config
│   ├── environments
│   ├── initializers
│   ├── locales
│   └── robots
├── db
│   ├── images                  # Some seed images - not been looked at for a while
│   │   ├── sites
│   │   └── supporters
│   ├── migrate
│   └── seeds                   # Seeds to make a test site - currently semi working
├── doc                         # Another directory that probably needs either deleting or reworking!
│   └── adr                     # Architectural decision records, used in the early stage of the project then dropped off
├── lib
│   ├── assets
│   ├── data                    # UK geography ward to district data used to create neighbourhood info
│   ├── tasks                   # Rake tasks that create ActiveJobs
│   └── templates
│       └── erb                 # Rails scaffold templates
├── log
├── nginx.conf.d                # Config files here get added to the nginx config by dokku
├── public
├── scripts
├── test
│   ├── components
│   ├── controllers
│   ├── factories
│   ├── fixtures
│   │   ├── files
│   │   └── vcr_cassettes       # These record actual output from iCal/API endpoints so we can test against them
│   ├── helpers
│   ├── integration
│   │   ├── admin
│   │   └── graphql             # API tests
│   ├── jobs
│   ├── mailers
│   │   └── previews
│   ├── models
│   ├── policies
│   ├── support
│   │   └── api
│   └── system                  # Capybara tests for things that need JavaScript
│       ├── admin
│       └── graphql
```

## API

API examples and test environment are provided using [Bruno](https://www.usebruno.com/).

Install it with your system package manager then point it at the `collections` directory.

## Donations

If you'd like to support development, please consider sending us a one-off or regular donation on Ko-fi. You can do this through the "support" button in GitHub at the top of this repo.
