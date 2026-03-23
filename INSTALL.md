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

### 3. Configure Cloudflare

PlaceCal uses Cloudflare proxy (orange cloud) for DDoS protection and caching. Since Cloudflare intercepts port 80, Let's Encrypt HTTP-01 challenges won't work. Instead, we use a **Cloudflare Origin CA certificate** that kamal-proxy serves directly.

#### Create an Origin CA certificate

1. Go to **Cloudflare dashboard → SSL/TLS → Origin Server → Create Certificate**.
2. Let Cloudflare generate a private key (RSA).
3. Set hostnames to `placecal.org`, `*.placecal.org` (or `placecal-staging.org`, `*.placecal-staging.org` for staging).
4. Set validity to **15 years**.
5. Copy the **Origin Certificate** (PEM) and **Private Key** (PEM).

#### Store the certificate

The PEM values must be available as environment variables for Kamal:

- **Local deploys**: export `SSL_CERTIFICATE_PEM` and `SSL_PRIVATE_KEY_PEM` in your shell (or add to `.kamal/secrets.staging` / `.kamal/secrets.production`).
- **CI deploys**: add both as GitHub repository secrets (`SSL_CERTIFICATE_PEM`, `SSL_PRIVATE_KEY_PEM`).

#### DNS records

Add **A records** for the root domain and any subdomains, all pointing to the server IP with **Proxy status: Proxied** (orange cloud):

| Type | Name                 | Content       | Proxy   |
| ---- | -------------------- | ------------- | ------- |
| A    | `placecal.org`       | `<server IP>` | Proxied |
| A    | `admin.placecal.org` | `<server IP>` | Proxied |

#### SSL/TLS settings

- **Encryption mode**: Full (Strict) — Origin CA certs are trusted by Cloudflare.
- **Edge Certificates → Always Use HTTPS**: On.
- **Edge Certificates → Minimum TLS Version**: 1.2.

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

## Recurring jobs

Recurring tasks (calendar import scanning, deduplication, counter refresh, address cleanup) run as self-scheduling delayed jobs inside the `job_worker` container. They are seeded on boot by `config/initializers/recurring_jobs.rb` and re-enqueue themselves after each run.

## Syncing data between environments

```sh
# Sync production database to staging
export PRODUCTION_HOST="<production-ip>"
export STAGING_HOST="<staging-ip>"
rake db:sync_prod_staging

# Sync uploads from production to staging
rake db:sync_uploads

# Download production database to local machine
export PRODUCTION_HOST="<production-ip>"
rake db:dump_production

# Download uploads to local machine
rake db:get_files
```

## Teardown

```sh
kamal remove -d production
```

This stops all containers and removes the app from the server. Database volumes are preserved — delete `/data/placecal/` on the server to fully clean up.
