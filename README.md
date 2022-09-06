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
      -  `libpq-dev` (debian)
      -  `postgresql-libs` (arch)
      -  `dev-db/postgresql` (gentoo)
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

### Set up postgresql server (Via docker)

**Note: Skip this step if you're using a system-installed docker**

Creating a postgres docker image is reasonably quick:

``` sh
docker network create placecal-network
docker create --name placecal-db --network placecal-network --network-alias postgres -p 5432:5432 --health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5 -e 'POSTGRES_DB=placecal_db' -e 'POSTGRES_USER=postgres' -e 'POSTGRES_PASSWORD=foobar' -e 'POSTGRES_PORT=5432' postgres:14.1
docker start placecal-db
```

Make a copy of `.env.example` in `.env` in the root directory of the application. These will be loaded in as environment variables when you start the development server.

You can now set the following in `.env`:

``` sh
POSTGRES_HOST=localhost
POSTGRES_USER=postgres
PGPASSWORD=foobar
```

### Set up the local placecal repository, set up the database, and run it

```
git clone https://github.com/geeksforsocialchange/PlaceCal.git
bundle && yarn
bundle exec rails db:setup db:migrate seed:migrate
bundle exec rails import:all_events
./bin/dev
```

* Start the server with `./bin/dev` instead of `bundle exec rails server` due to migration to jsbundling
* Make sure you use `lvh.me:3000` instead of `localhost` or you **will** have authentication problems.
* Admin interface is `admin.lvh.me:3000` (You will need to make a new admin user -- see below)
* Access code docs through your local filesystem, and update with `bundle exec rails yard`

To set up your own server, take a look at `INSTALL.md`.

### Creating an admin user

To create an admin user, open the console (`bin/rails c`) and run the following:

```
User.create!(email: 'info@placecal.org', password: 'password', password_confirmation: 'password', role: :root)
```

(Note: You should replace 'info@placecal.org' and 'password' with more appropriate values)

## Testing

PlaceCal tests are written in minitest. Before running the tests please ensure your dev environment has all of the migrations run, and ensure you have loaded the schema into the test database by running:

``` sh
rails db:test:prepare
```

The following commands are used for running tests:

``` sh
rails test        # To run all of the unit tests
rails test:system # To run all of the system tests (Invokes a headless browser)
rails test:all    # To run both the unit tests and the system tests at once
```

Please note that when running unit tests, system tests are **not** run, this is because they can take a while to run and are quite resource intensive. To perform more advanced usage like executing only a specific test or test file, see the documentation [here](https://guides.rubyonrails.org/testing.html)

When pushing to a branch on github all tests are run (unit and system). This is configured [here](.github/workflows/test.yml). You are not allowed to merge a branch (onto main or production) without a passing test suite.

## Contributing

We welcome new contributors but strongly recommend you have a chat with us in [Geeks for Social Change's Discord server](http://discord.gfsc.studio) and say hi before you do. We will be happy to onboard you properly before you get stuck in.

## Donations

If you'd like to support development, please consider sending us a one-off or regular donation on Ko-fi.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/M4M43THUM)
