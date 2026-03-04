# Deploying PlaceCal with Kamal

PlaceCal is deployed using [Kamal 2](https://kamal-deploy.org/) to Hetzner Cloud (or any Ubuntu VPS with Docker).

## Prerequisites

On your **local machine**:

- Ruby (see `.ruby-version`)
- Kamal: `gem install kamal` (or use the bundled version via `bundle exec kamal`)

On the **server**:

- Ubuntu 22.04+ (Kamal installs Docker automatically on first setup)
- SSH access as root with key-based authentication

## Server provisioning

### 1. Create a server

Create a Hetzner Cloud server (CX23 for staging, CX33 for production) with Ubuntu 22.04+. Note the IP address.

### 2. Basic server hardening

```sh
ssh root@SERVER_IP

# Firewall — allow only SSH, HTTP, HTTPS
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# Automatic security updates
apt update && apt install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Disable password auth (ensure your SSH key is already added)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh
```

### 3. Configure Cloudflare DNS

1. Add an **A record** pointing to the server IP with Cloudflare **proxy enabled** (orange cloud).
2. Set SSL/TLS mode to **Full (Strict)**.
3. Kamal's Let's Encrypt on the origin handles the Cloudflare-to-origin TLS connection.

## Kamal setup

### 1. Configure secrets

Set these environment variables in your shell or CI:

```sh
# Server + registry
export PRODUCTION_HOST="<server-ip>"          # or STAGING_HOST for staging
export KAMAL_REGISTRY_USERNAME="<github-username>"
export KAMAL_REGISTRY_PASSWORD="<github-pat>"

# Rails
export RAILS_ENV="production"                 # or "staging"
export SECRET_KEY_BASE="<generate with: rails secret>"
export RAILS_MASTER_KEY="<from config/master.key>"
export SITE_DOMAIN="placecal.org"             # or "placecal-staging.org"

# Database
export POSTGRES_HOST="placecal-db"
export POSTGRES_PORT="5432"
export POSTGRES_DB="placecal_production"
export POSTGRES_USER="placecal"
export POSTGRES_PASSWORD="<strong password>"  # mapped to PGPASSWORD via .kamal/secrets

# Services
export MAILERSEND_USERNAME="<smtp username>"
export MAILERSEND_PASSWORD="<smtp password>"
export APPSIGNAL_PUSH_API_KEY="<key>"
export EVENTBRITE_TOKEN="<token>"
```

### 2. First deploy

```sh
# This installs Docker, sets up the database, builds and pushes the image,
# and starts the app with kamal-proxy handling SSL.
kamal setup -d production
```

### 3. Verify

```sh
kamal app details -d production
curl -I https://placecal.org
```

## Ongoing operations

```sh
# Deploy latest code
kamal deploy -d production

# View logs
kamal app logs -d production

# Open a Rails console
kamal app exec -d production 'bin/rails console'

# Run a rake task
kamal app exec -d production 'bin/rails db:migrate'

# Rollback to previous version
kamal rollback -d production
```

## Cron jobs

Cron jobs are managed by the [whenever](https://github.com/javan/whenever) gem and run in a dedicated `cron` container role (defined in `config/deploy.yml`). The schedule is defined in `config/schedule.rb` and deploys automatically with the app — no manual server configuration needed.

To preview the generated crontab:

```sh
bundle exec whenever
```

## Migrating uploads from old server

```sh
# From the old Dokku server to the new Hetzner server
rsync -avz --progress \
  root@old-server:/var/lib/dokku/data/storage/placecal/public/uploads/ \
  root@new-server:/data/placecal/uploads/
```

## Teardown

```sh
kamal remove -d production
```

This stops all containers and removes the app from the server. Database volumes are preserved — delete `/data/placecal/` on the server to fully clean up.
