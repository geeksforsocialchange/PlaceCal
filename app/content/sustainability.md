PlaceCal is built to be light. We measure the energy and data it takes to run PlaceCal and to find an event on it, and publish the results here with how we got them. We update this page whenever we make a change that affects them.

**Last measured: 3 November 2026.**

## Summary

- PlaceCal runs on Hetzner Cloud in Nuremberg, Germany, behind Cloudflare. Both say they power their operations with 100% renewable electricity ([Hetzner](https://www.hetzner.com/unternehmen/nachhaltigkeit/), [Cloudflare](https://www.cloudflare.com/impact/)), and the [Green Web Foundation](https://www.thegreenwebfoundation.org/green-web-check/) lists both as green hosts.
- Running PlaceCal produces an estimated **under 35 kg CO2e a year**.
- Finding an event on PlaceCal transfers under 1.5 MB of data the first time and under 70 KB after that.

## Finding an event

We measured the same task on each platform: find a queer event in Manchester. That means opening the event listing or search, scrolling down three screens, and opening one event at a venue.

| Platform                               | First visit | Repeat visit  | CO2e, first visit | CO2e, repeat visit |
| -------------------------------------- | ----------- | ------------- | ----------------- | ------------------ |
| placecal.org                           | 0.9 MB      | 68 KB         | 0.11 g            | 0.008 g            |
| The Trans Dimension (runs on PlaceCal) | 1.3 MB      | 22 KB         | 0.17 g            | 0.003 g            |
| Eventbrite                             | 6.0 MB      | 140 to 260 KB | 0.74 g            | 0.02 to 0.03 g     |
| Facebook, logged in                    | 15.5 MB     | 4.4 MB        | 1.9 g             | 0.55 g             |

On a first visit, finding an event on PlaceCal uses 78 to 85% less data, and so less CO2e, than Eventbrite, and 91 to 94% less than Facebook. On a repeat visit it uses at least 50% less than Eventbrite and over 98% less than Facebook.

A first visit starts with nothing saved in the browser. A repeat visit is the same journey again, when the browser already has some files saved. Most people who find events on Facebook use it regularly, so for them the repeat visit is the closer comparison.

We left Eventbrite's cookie banner unanswered, so advertising scripts that load after accepting cookies aren't counted and its figures are a minimum.

## Running PlaceCal

We estimate that running PlaceCal produces under 35 kg CO2e a year, from the data our server sends to people viewing pages and to automated crawlers.

Automated crawlers account for more of PlaceCal's footprint than people do. Each crawler request is small, because crawlers fetch a page's text without its images, fonts or maps, but there are far more of them.

The highest possible figure, counting all the data our server sends, is about 200 kg CO2e a year.

For the full calculation, including the traffic figures behind it, email [support@placecal.org](mailto:support@placecal.org).

## What we're working on

- Cutting crawler traffic, our biggest source of emissions
- Serving smaller hero images on site homepages
- Loading fewer and smaller font files

## How we measured

- **Data per journey**: for PlaceCal and Eventbrite, we ran each journey twice in an automated Chrome browser at desktop size, counting every file transferred, including maps and files from other services. The figures matched apart from Eventbrite's repeat visit, shown as a range. Facebook needs an account, so we measured it once in a logged-in Chrome browser: the first visit in Chrome's developer tools with the cache turned off, and the repeat visit in a browser that already uses Facebook.
- **Hosting**: checked with the Green Web Foundation's green web check.
- **Traffic**: page requests from our server monitoring over 90 days, and page views from our own analytics (Matomo) over 12 months. Page views by people are doubled to allow for visitors who block analytics.
- **Carbon**: calculated with [CO2.js](https://www.thegreenwebfoundation.org/co2-js/) using the Sustainable Web Design model (version 4), with green hosting. That gives about 0.12 g CO2e per MB transferred. Crawler requests are counted without the share for the viewer's device, since no one views them.
- **Not included**: making the servers beyond the share the model includes, and our staff travel and office energy.

The full method and the scripts we use are [on GitHub](https://github.com/geeksforsocialchange/PlaceCal/blob/main/doc/sustainability.md). If you spot a mistake, email [support@placecal.org](mailto:support@placecal.org).
