# PlaceCal

## Introduction

PlaceCal is an online calendar which lists events and activities by and for members of local communities, curated around interests and locality.

The codebase doesn't currently have enough seeds to create a dev environment suitable for developing from scratch. If you're interested in contributing to PlaceCal please get in touch at support@placecal.org

To get an idea of the project and what we're about, check out [the handbook](https://handbook.placecal.org/).

## Requirements

To run PlaceCal locally you will need to install the following dependencies:

- [Docker](https://docs.docker.com/get-docker/)
- [Ruby 3.1.2](https://www.ruby-lang.org/en/news/2022/04/12/ruby-3-1-2-released/)
- [Node.js](https://nodejs.org/en/download) 16.x & (optional) [nvm](https://github.com/nvm-sh/nvm) to manage it
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

- Username: `root@placecal.org`
- Password: `password`

### Run the thing

- Start the server with `bin/dev`
- Make sure you use `lvh.me:3000` instead of `localhost:3000` or you **will** have authentication problems
- The admin interface is at `admin.lvh.me:3000`
- Access code docs through your local filesystem and update them with `bin/rails yard`

## Testing, linting and formatting

PlaceCal tests are written in minitest. We use Rubocop to lint our Ruby code.

We use [Prettier](https://prettier.io/) to format everything it's able to parse. We run this automatically as part of a pre-commit hook.

You can run the tests & rubocop with:

```sh
make test
```

## Documentation for Developers

The documentation for PlaceCal is currently stored in notion and can be read [here](https://handbook.placecal.org/placecal-developer-handbook).

The developer Procfile will load a yard language server, this is visible at `http://localhost:8808`.

If you are working with the code and are completely lost you can also try the [GFSC discord server](http://discord.gfsc.studio) where you can prod a human for answers. Good Luck!

### Generating new components

We use view_component to make components, and you can create a new one by running `rails g component <Name> <args>`
Previously this system used mountain view, and some of the components are still generated using this.
More info here: https://viewcomponent.org/guide/generators.html

## Donations

If you'd like to support development, please consider sending us a one-off or regular donation on Ko-fi. You can do this through the "support" button in GitHub at the top of this repo.
