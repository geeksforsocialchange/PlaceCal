# External sites

A site can have its own website on a domain PlaceCal doesn't serve, such as `fruitsaladevents.co.uk`. Set that domain on the site, and leave it out of the production host list.

PlaceCal links to a partner on an external website by partner ID, for example `https://fruitsaladevents.co.uk/partners/392`. The website needs a page or a redirect at `/partners/<partner ID>` for every partner on the site, or those links show its 404 page.

Partner IDs are in the GraphQL API at `/api/v1/graphql`.
