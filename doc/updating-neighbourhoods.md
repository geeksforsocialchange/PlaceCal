# Updating neighbourhoods

Placecal depends upon data from ONS (Office of National Statistics) and postcodes.io to map postcodes to neighbourhoods.

These are how Sites find their Partners or Events through Addresses or Service Areas.

The data in the Neighbourhoods table may become obsolete as the ONS datasets are updated. This can result in newer postcodes not being found.

This document describes the procedure for updating neighbourhoods.

It is expected that when this task needs to be done it will be done on a local dev machine first, then staging, then production. Hopefully this will minimize any problems from affecting clients/the public.

## Download new data

Check out the [ONS Open Geography Portal](https://geoportal.statistics.gov.uk/search?collection=Dataset&q=Ward%20to%20Local%20Authority%20District%20to%20County%20to%20Region%20to%20Country%20Lookup) and look for something titled like "Ward to Local Authority District to County to Region to Country (May 2023) Lookup in United Kingdom". Download and extract this into the PlaceCal repo in `/lib/data/`. You then want to open `/lib/tasks/neighbourhoods.rake` (around line 150) and add a line like:

```ruby
load_csv(
  DateTime.new(2019, 12),
  'Ward_to_Local_Authority_District_to_County_to_Region_to_Country_(December_2019)_Lookup_in_United_Kingdom.csv'
)
```

With the correct name and Date (!!THIS IS VERY IMPORTANT!!). Just put it after the rest. You can now run the rest of the procedure. The new dataset file and modified script must be commited to the repo and merged on to main when it comes to updating staging or production.

## Perform the update

Once done there is only one command to run

```bash
rails neighbourhoods:import
```

## Fin

Congratulations, neighbourhoods should now be up to date.
