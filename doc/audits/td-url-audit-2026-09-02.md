# TransDimension URL Audit

Superseded: this is the pre-fix run. See [td-url-audit-2026-09-03.md](td-url-audit-2026-09-03.md) for the post-fix audit.

Date: 2026-09-02

## Summary

| Verdict         | Count |
| --------------- | ----- |
| OK              | 104   |
| MISSING         | 5     |
| NO ROUTE        | 0     |
| REDIRECT NEEDED | 0     |

## Details

| Path                                              | TD Status | Route          | PC Status | Verdict       |
| ------------------------------------------------- | --------- | -------------- | --------- | ------------- |
| `/`                                               | 200       | pages#home     | 200       | OK            |
| `/about`                                          | 308       | pages#show     | 404       | MISSING       |
| `/privacy`                                        | 308       | pages#privacy  | 200       | OK            |
| `/events`                                         | 308       | events#index   | 200       | OK            |
| `/news`                                           | 308       | news#index     | 302       | UNKNOWN (302) |
| `/partners`                                       | 308       | partners#index | 200       | OK            |
| `/join-us`                                        | 308       | pages#show     | 404       | MISSING       |
| `/events/397406`                                  | 308       | events#show    | 200       | OK            |
| `/events/397407`                                  | 308       | events#show    | 200       | OK            |
| `/events/397408`                                  | 308       | events#show    | 200       | OK            |
| `/events/397409`                                  | 308       | events#show    | 200       | OK            |
| `/events/397410`                                  | 308       | events#show    | 200       | OK            |
| `/events/397411`                                  | 308       | events#show    | 200       | OK            |
| `/events/403955`                                  | 308       | events#show    | 200       | OK            |
| `/events/403958`                                  | 308       | events#show    | 200       | OK            |
| `/events/405345`                                  | 308       | events#show    | 200       | OK            |
| `/events/405346`                                  | 308       | events#show    | 200       | OK            |
| `/events/405347`                                  | 308       | events#show    | 200       | OK            |
| `/events/405348`                                  | 308       | events#show    | 200       | OK            |
| `/events/405349`                                  | 308       | events#show    | 200       | OK            |
| `/events/405350`                                  | 308       | events#show    | 200       | OK            |
| `/events/405351`                                  | 308       | events#show    | 200       | OK            |
| `/events/405352`                                  | 308       | events#show    | 200       | OK            |
| `/events/405353`                                  | 308       | events#show    | 200       | OK            |
| `/events/405356`                                  | 308       | events#show    | 200       | OK            |
| `/events/405357`                                  | 308       | events#show    | 200       | OK            |
| `/events/405358`                                  | 308       | events#show    | 200       | OK            |
| `/events/405359`                                  | 308       | events#show    | 200       | OK            |
| `/events/405360`                                  | 308       | events#show    | 200       | OK            |
| `/events/405362`                                  | 308       | events#show    | 200       | OK            |
| `/events/405363`                                  | 308       | events#show    | 200       | OK            |
| `/events/405364`                                  | 308       | events#show    | 200       | OK            |
| `/events/405365`                                  | 308       | events#show    | 200       | OK            |
| `/events/405366`                                  | 308       | events#show    | 200       | OK            |
| `/events/405367`                                  | 308       | events#show    | 200       | OK            |
| `/events/405368`                                  | 308       | events#show    | 200       | OK            |
| `/events/405369`                                  | 308       | events#show    | 200       | OK            |
| `/events/405370`                                  | 308       | events#show    | 200       | OK            |
| `/events/405371`                                  | 308       | events#show    | 200       | OK            |
| `/events/405372`                                  | 308       | events#show    | 200       | OK            |
| `/events/405378`                                  | 308       | events#show    | 200       | OK            |
| `/events/405379`                                  | 308       | events#show    | 200       | OK            |
| `/events/405380`                                  | 308       | events#show    | 200       | OK            |
| `/events/405381`                                  | 308       | events#show    | 200       | OK            |
| `/events/405382`                                  | 308       | events#show    | 200       | OK            |
| `/events/405383`                                  | 308       | events#show    | 200       | OK            |
| `/events/405384`                                  | 308       | events#show    | 200       | OK            |
| `/events/405385`                                  | 308       | events#show    | 200       | OK            |
| `/events/405386`                                  | 308       | events#show    | 200       | OK            |
| `/events/405387`                                  | 308       | events#show    | 200       | OK            |
| `/events/405388`                                  | 308       | events#show    | 200       | OK            |
| `/events/405389`                                  | 308       | events#show    | 200       | OK            |
| `/events/405390`                                  | 308       | events#show    | 200       | OK            |
| `/events/405391`                                  | 308       | events#show    | 200       | OK            |
| `/events/405392`                                  | 308       | events#show    | 200       | OK            |
| `/events/405393`                                  | 308       | events#show    | 200       | OK            |
| `/events/405394`                                  | 308       | events#show    | 200       | OK            |
| `/partners/123`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/124`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/125`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/128`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/129`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/130`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/131`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/132`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/133`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/134`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/135`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/136`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/137`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/138`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/140`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/141`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/142`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/143`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/144`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/146`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/147`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/148`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/149`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/150`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/151`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/152`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/153`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/154`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/156`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/163`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/167`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/169`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/170`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/172`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/173`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/174`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/175`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/176`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/177`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/179`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/188`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/190`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/191`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/192`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/193`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/194`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/195`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/198`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/208`                                   | 308       | partners#show  | 200       | OK            |
| `/partners/209`                                   | 308       | partners#show  | 200       | OK            |
| `/news/can-you-help-out-with-the-trans-dimension` | 308       | news#show      | 302       | UNKNOWN (302) |
| `/news/greater-manchester-trans-organisers-fund`  | 308       | news#show      | 302       | UNKNOWN (302) |
| `/news/introducting-g-end-er-swap`                | 308       | news#show      | 404       | MISSING       |
| `/news/the-outside-project-joins`                 | 308       | news#show      | 404       | MISSING       |
| `/news/the-trans-dimension-is-now-in-manchester`  | 308       | news#show      | 302       | UNKNOWN (302) |
| `/news/the-trans-dimension-launches`              | 308       | news#show      | 302       | UNKNOWN (302) |
| `/news/welcoming-velociposse`                     | 308       | news#show      | 404       | MISSING       |
