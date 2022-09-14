# PlaceCal

## Introduction / Warning

PlaceCal is a large and very complicated app for collating organisation and event information from a large variety of sources. In the words of one developer: "I'm not sure where the interface between the app and the real world is here".

To get an idea of the project and what we're about, check out [the handbook](https://handbook.placecal.org/).

## Requirements

To run PlaceCal locally you will need:

- A Mac or a Linux machine (we don't support Windows at present)
- Postgres relational database. We are currently using v14.
  - Server
    - either installed for your distribution or as a docker image (with the correct open port -- see below)
  - Client
    - you will still need the local developer libraries for postgres
    - these are distribution specific so you need to find out what they are called to install them
      - `libpq-dev` (debian)
      - `postgresql-libs` (arch)
      - `dev-db/postgresql` (gentoo)
- Ruby 2.7.x. We reccomend using a version manager for this such as `rvm` or `rbenv`. Current version we are using is in `.ruby-version`.
  - [rvm](https://rvm.io/)
  - [rbenv](https://github.com/rbenv/rbenv)
    - [ruby-build](https://github.com/rbenv/ruby-build)
    - [rbenv-gemset](https://github.com/jf/rbenv-gemset) (optional)
- Node.js 16.x. We recommend using a version manager for this such as `nvm` or `nodenv`. Current version we are using is in `.node-version`.
  - [nvm](https://github.com/nvm-sh/nvm)
  - [nodenv](https://github.com/nodenv/nodenv)
- Yarn 1.x
  - [yarn](https://classic.yarnpkg.com/en/docs/install)
- ImageMagick for image manipulation
- [Graphviz](https://voormedia.github.io/rails-erd/install.html) for documentation diagrams
- Chrome/Chromium for system tests

## Quickstart

With that said, here's what you need to get rolling.

### Set up Postgresql locally

If you don't already have Postgresql installed and running, here's how you can set it up with Docker.

**Skip these steps if you already have Postgresql set up.**

Creating a Postgresql Docker image is reasonably quick:

```sh
docker network create placecal-network
docker create --name placecal-db --network placecal-network --network-alias postgres -p 5432:5432 --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5 -e 'POSTGRES_DB=placecal_db' -e 'POSTGRES_USER=postgres' -e 'POSTGRES_PASSWORD=foobar' -e 'POSTGRES_PORT=5432' postgres:14.1
docker start placecal-db
```

Make a copy of `.env.example` in `.env` in the root directory of the application. These will be loaded in as environment variables when you start the development server.

You can now set the following in `.env`:

```sh
POSTGRES_HOST=localhost
POSTGRES_USER=postgres
PGPASSWORD=foobar
```

### Clone this Git repository

```sh
git clone https://github.com/geeksforsocialchange/PlaceCal.git
cd PlaceCal
```

### Run the setup script

```sh
bin/setup
```

Amongst other things, this will create an admin user for you:

- Username: `admin@placecal.org`
- Password: `password`

### Run the thing

- Start the server with `bin/dev`
- Make sure you use `lvh.me:3000` instead of `localhost:3000` or you **will** have authentication problems
- The admin interface is at `admin.lvh.me:3000`
- Access code docs through your local filesystem and update them with `bin/rails yard`

## Testing

PlaceCal tests are written in minitest. Before running the tests please ensure your dev environment has all of the migrations run, and ensure you have loaded the schema into the test database by running:

```sh
bin/rails db:test:prepare
```

The following commands are used for running tests:

```sh
bin/rails test        # To run all of the unit tests
bin/rails test:system # To run all of the system tests (Invokes a headless browser)
bin/rails test:all    # To run both the unit tests and the system tests at once
```

Please note that when running unit tests, system tests are **not** run, this is because they can take a while to run and are quite resource intensive. To perform more advanced usage like executing only a specific test or test file, see the documentation [here](https://guides.rubyonrails.org/testing.html)

When pushing to a branch on github all tests are run (unit and system). This is configured [here](.github/workflows/test.yml). You are not allowed to merge a branch (onto main or production) without a passing test suite.

## Formatting

We use [Prettier](https://prettier.io/) to format everything it's able to parse. It will run as a pre-commit hook and format your changes as you make commits so you shouldn't have to think about it much.

If you do want to run it manually, you can:

```sh
bin/yarn run format
```

Note that we use tabs over spaces because [tabs are more accessible to people using braille displays](https://twitter.com/Rich_Harris/status/1541761871585464323).

## Contributing

We welcome new contributors but strongly recommend you have a chat with us in [Geeks for Social Change's Discord server](http://discord.gfsc.studio) and say hi before you do. We will be happy to onboard you properly before you get stuck in.

## Donations

If you'd like to support development, please consider sending us a one-off or regular donation on Ko-fi.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/M4M43THUM)
