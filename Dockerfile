# syntax=docker/dockerfile:1
# check=error=true

# Multi-stage Dockerfile for PlaceCal
# Used by Kamal for production deployments

ARG RUBY_VERSION=4.0.1
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install base packages (cron needed for the cron container role)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      cron curl imagemagick libjemalloc2 libpq5 libvips && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test:ai"

# ---------- Build stage ----------
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libpq-dev libvips-dev pkg-config \
      imagemagick libmagickwand-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Node.js
ARG NODE_VERSION=24.14.0
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    rm -rf /tmp/node-build-master

# Install yarn
RUN npm install -g yarn

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install Node packages
COPY package.json yarn.lock ./
RUN yarn install --immutable

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot
RUN bundle exec bootsnap precompile app/ lib/

# Build Tailwind CSS
RUN yarn build

# Precompile assets (sprockets + importmap)
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ---------- Runtime stage ----------
FROM base

# Copy built artifacts
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run as non-root user for security (web + job_worker roles).
# The cron role overrides this via Docker --user flag or runs cron as root.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log tmp public

USER 1000:1000

# Entrypoint prepares the database
ENTRYPOINT ["./bin/docker-entrypoint"]

# Default command starts the Rails server
EXPOSE 3000
CMD ["./bin/rails", "server"]
