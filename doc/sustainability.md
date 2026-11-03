# Measuring PlaceCal's climate impact

The public page at [placecal.org/sustainability](https://placecal.org/sustainability) (`app/content/sustainability.md`) publishes PlaceCal's measured footprint. Re-measure and update it whenever a change affects page weight, hosting or traffic, and at least once a year. Change the "Last measured" date on the page each time.

## 1. Hosting

Check each server and CDN host with the Green Web Foundation API:

```bash
for host in placecal.org transdimension.uk <production server IP>; do
  curl -s "https://api.thegreenwebfoundation.org/api/v3/greencheck/$host" | jq '{url, green, hosted_by}'
done
```

## 2. Finding an event

`bin/measure-journey` loads an event listing in headless Chromium (Playwright, from `node_modules`), scrolls three screens, opens the first event matching a pattern, then repeats the journey with the browser cache warm. It counts every byte transferred, including third-party files and map tiles.

```bash
bin/measure-journey https://placecal.org/events '/events/[0-9]+$'
bin/measure-journey 'https://transdimension.uk/events?region=trans-dimension-manchester' '/events/[0-9]+$'
bin/measure-journey 'https://www.eventbrite.co.uk/d/united-kingdom--manchester/queer/' '/e/[^?]+-tickets-[0-9]+'
```

Pick an event at a venue, so its page includes the map. Run each journey twice and check the figures match.

Logged-in Facebook needs a real account, so measure it by hand in Chrome:

1. Open DevTools, then **Network**, and tick **Disable cache**.
2. In **Application**, then **Service workers**, tick **Bypass for network**.
3. Load `https://www.facebook.com/events/search/?q=queer%20manchester`, scroll three screens, and open the first event.
4. Read **transferred** at the bottom of the Network tab.

For the repeat visit, untick both boxes and repeat the journey.

## 3. Traffic

- **Page requests**: in AppSignal (PlaceCal, production), sum `transaction_duration` count for the `public` and `web` namespaces over the last 90 days and scale to a year.
- **Human page views**: count visits and page views for PlaceCal's Matomo site over the last 12 months, from the Matomo dashboard or its database. The Matomo instance tracks other sites too; every PlaceCal domain reports as site 1 (`setSiteId` in `app/views/layouts/application.rb`).

The exact commands for these counts are in the GFSC ops runbook.

## 4. Carbon

Use [CO2.js](https://www.thegreenwebfoundation.org/co2-js/) with the Sustainable Web Design model v4 and green hosting. With CO2.js 0.19 the full rate (`total`) is 121 g CO2e per GB, and the data centre and network rate (`dataCenterCO2e` plus `networkCO2e`) is 69 g per GB.

```bash
npx -p @tgwf/co2 node -e 'const {co2}=require("@tgwf/co2"); console.log(new co2({model:"swd",version:4,results:"segment"}).perByte(1e9, true))'
```

- **People**: page views × 800 KB (most visits are one page on an empty cache), doubled to allow for visitors who block Matomo, at the full rate.
- **Crawlers**: page requests minus human page views, × 10 KB of compressed HTML each, at the data centre and network rate only (no viewer device).
- **Upper bound**: the production server's yearly outbound data (its network counters, divided by uptime) at the data centre and network rate, plus the human figure.

Per-journey CO2e is the journey's data at the full rate (about 0.12 g per MB).
