# Updating neighbourhoods

Placecal depends upon data from ONS and postcodes.io to map postcodes to neighbourhoods.

These are how Sites find their Partners or Events through Addresses or Service Areas.

The data in the Neighbourhoods table may become obsolete as the ONS datasets are updated. This can result in newer postcodes not being found.

This document describes the procedure for updating neighbourhoods.

It is expected that when this task needs to be done it will be done on a local dev machine first, then staging, then production. Hopefully this will minimize any problems from affecting clients/the public.

## Download new data

## Perform the update

Run these scripts

```bash

# saving what is in the database
rails neighbourhoods:bulk_lookup_address_postcodes
rails neighbourhoods:capture_site_relations

# loading new neighbourhoods in
rails neighbourhoods:import

# now perform the verification
```

## verifying address postcodes

The script tries to resolve postcodes that were looked up earlier against our neighbourhoods table as if the address was being validated from the front end.

```
rails neighbourhoods:verify_address_postcodes
```

Has the following output

```
Address Postcode verifier
  loading from /.../place-cal/tmp/address-postcodes-lookup.json
  read 269 postcodes
  'WN74ND' -> 2019
  'M403SL.' not found in postcodes.io response
  'OL59RR' -> 2019
  'M80PF' -> 2023
  'M15' not found in postcodes.io response
  'M114SG' -> 2023
  'M34FP' -> 2023
  'OL59AY' -> 2019
  'WC2N6HH' not found in neighbourhood

```

Where each postcode is matched to a neighbourhood printing its version year. Problems: "not found in postcodes.io response" means that it is no longer an active postcode (the response was an error) and "not found in neighbourhood" means the postcode is missing from our dataset.

## verifying site neighbourhoods

This script uses the previously captured site data to determine if something has gone wrong with the update. Currently it performs a sanity test on direct site neighbourhood relations where each site has a link to a neighbourhood. These should never change (as we are only adding neighbourhoods). It then does a deeper check for all the neighbourhoods and their children. Again neighbourhoods should never be removed and it will warn you if that happens. It will also show how many new neighbourhoods exist for this site.

Example output:

```
Site relation verifier
  loading from /.../place-cal/tmp/site-relations.json
  read 23 sites
  C2 Connecting Communities
    all_neighbourhoods_added.count=3319
  Conscious Collective Manchester
  Flourish Together
    all_neighbourhoods_added.count=2557
  GM Systems Changers
    all_neighbourhoods_added.count=2557
  Marvellous Mossley
  Norwich
  OL1 Oldham
  PlaceCal
  PlaceCal Ardwick
  PlaceCal Beeston
  PlaceCal Christchurch
  PlaceCal East Berwickshire
  PlaceCal Hulme
  PlaceCal London
    all_neighbourhoods_added.count=530
  PlaceCal Manchester
  PlaceCal Moss Side
  PlaceCal Moston
  PlaceCal Oldham
    all_neighbourhoods_added.count=20
  PlaceCal Rusholme
  PlaceCal Torbay
  PlaceCal West Vale
  Test Site
  The Trans Dimension
    all_neighbourhoods_added.count=3341

```
