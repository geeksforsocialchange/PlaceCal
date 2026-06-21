# syntax=docker/dockerfile:1
# check=error=true

# Multi-stage Dockerfile for PlaceCal
# Used by Kamal for production deployments

ARG RUBY_VERSION=4.0.2
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
      build-essential git libpq-dev libvips-dev libyaml-dev pkg-config \
      imagemagick libmagickwand-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Node.js from the official dist (arch-aware, checksum-verified).
# renovate: datasource=node-version depName=node
ARG NODE_VERSION=24.17.0
ENV PATH=/usr/local/node/bin:$PATH
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) node_arch="x64" ;; \
      arm64) node_arch="arm64" ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    tarball="node-v${NODE_VERSION}-linux-${node_arch}.tar.gz"; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/${tarball}"; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" \
      | grep " ${tarball}\$" | sha256sum -c -; \
    mkdir -p /usr/local/node; \
    tar -xzf "${tarball}" -C /usr/local/node --strip-components=1 --no-same-owner; \
    rm "${tarball}"; \
    node --version; npm --version

# Install yarn
RUN npm install -g yarn

# Install Ruby gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install Node packages
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot
RUN bundle exec bootsnap precompile app/ lib/

# Build Tailwind CSS (admin + public)
RUN yarn build

# Compile SCSS to CSS
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails dartsass:build

# Precompile assets (Propshaft fingerprinting + importmap)
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Remove node_modules — not needed at runtime (saves ~100-300MB)
RUN rm -rf node_modules

# ---------- Runtime stage ----------
FROM base

# Application version for display in the UI (admin sidebar + site footers).
# Computed on the host from `git describe --tags --always` and passed in by
# the deploy tooling (see config/deploy.yml `builder.args`). The `.git` dir is
# excluded from the build context (.dockerignore), so it cannot be derived here.
ARG APP_VERSION
ENV APP_VERSION=$APP_VERSION

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
