# TransDimension URL Audit

Date: 2026-09-03

TD: https://transdimension.uk

PlaceCal (production): https://placecal.org

Dev (this branch): http://transdimension.lvh.me:3030

## How to read this run

The **Dev Status** column is the one that matters: it is this branch running locally at `http://transdimension.lvh.me:3030`, so it shows the routing and redirect work in place. The **PC Status** column is live `placecal.org`, which has not had this branch deployed to it yet, so a 404 there is expected for anything fixed on the branch.

`NO DEV DATA` means the path works on production PlaceCal but 404s locally because the local database does not hold the production event, partner and article records. It is an absence of seed data, not a routing problem.

The three remaining `MISSING` rows are legacy news slugs. A PlaceCal article URL is derived from the article title, so reproducing these slugs needs the real production articles, which the dev database does not have. They 404 on production too, so they are unresolved rather than verified: they cannot be confirmed either way from a local run, and should be rechecked against production once this work is deployed.

## Summary

| Verdict      | Count |
| ------------ | ----- |
| OK           | 7     |
| NO DEV DATA  | 104   |
| MISSING      | 3     |
| NO ROUTE     | 0     |
| CHECK FAILED | 0     |

## Details

| Path                                              | TD Status | Route          | PC Status | Dev Status | Verdict     |
| ------------------------------------------------- | --------- | -------------- | --------- | ---------- | ----------- |
| `/`                                               | 200       | pages#home     | 200       | 200        | OK          |
| `/about`                                          | 308       | pages#show     | 404       | 200        | OK          |
| `/privacy`                                        | 308       | pages#privacy  | 200       | 200        | OK          |
| `/events`                                         | 308       | events#index   | 200       | 200        | OK          |
| `/news`                                           | 308       | news#index     | 302       | 200        | OK          |
| `/partners`                                       | 308       | partners#index | 200       | 200        | OK          |
| `/join-us`                                        | 308       | pages#show     | 404       | 301        | OK          |
| `/events/397406`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/397407`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/397408`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/397409`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/397410`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/397411`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/403955`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/403958`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405345`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405346`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405347`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405348`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405349`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405350`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405351`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405352`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405353`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405356`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405357`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405358`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405359`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405360`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405362`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405363`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405364`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405365`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405366`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405367`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405368`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405369`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405370`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405371`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405372`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405378`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405379`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405380`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405381`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405382`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405383`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405384`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405385`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405386`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405387`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405388`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405389`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405390`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405391`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405392`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405393`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/events/405394`                                  | 308       | events#show    | 200       | 404        | NO DEV DATA |
| `/partners/123`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/124`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/125`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/128`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/129`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/130`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/131`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/132`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/133`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/134`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/135`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/136`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/137`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/138`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/140`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/141`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/142`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/143`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/144`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/146`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/147`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/148`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/149`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/150`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/151`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/152`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/153`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/154`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/156`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/163`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/167`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/169`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/170`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/172`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/173`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/174`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/175`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/176`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/177`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/179`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/188`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/190`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/191`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/192`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/193`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/194`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/195`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/198`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/208`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/partners/209`                                   | 308       | partners#show  | 200       | 404        | NO DEV DATA |
| `/news/can-you-help-out-with-the-trans-dimension` | 308       | news#show      | 302       | 404        | NO DEV DATA |
| `/news/greater-manchester-trans-organisers-fund`  | 308       | news#show      | 302       | 404        | NO DEV DATA |
| `/news/introducting-g-end-er-swap`                | 308       | news#show      | 404       | 404        | MISSING     |
| `/news/the-outside-project-joins`                 | 308       | news#show      | 404       | 404        | MISSING     |
| `/news/the-trans-dimension-is-now-in-manchester`  | 308       | news#show      | 302       | 404        | NO DEV DATA |
| `/news/the-trans-dimension-launches`              | 308       | news#show      | 302       | 404        | NO DEV DATA |
| `/news/welcoming-velociposse`                     | 308       | news#show      | 404       | 404        | MISSING     |
