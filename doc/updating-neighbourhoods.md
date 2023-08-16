# Updating neighbourhoods

_PLEASE READ CAREFULLY._

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

With the correct name and Date (!!THIS IS VERY IMPORTANT!!) - just year and month will suffice.

## Perform the update

Once done there is only one command to run

```bash
rails neighbourhoods:import
```

You may wish to check this by openning a rails console and running `Neighbourhood.group(:release_date).count` and seeing how many neighbourhoods by release data are present.

Example:

```
irb(main):002:0> Neighbourhood.group(:release_date).count
   (6.3ms)  SELECT COUNT(*) AS count_all, "neighbourhoods"."release_date" AS neighbourhoods_release_date FROM "neighbourhoods" GROUP BY "neighbourhoods"."release_date"
=> {Mon, 01 May 2023 01:00:00.000000000 BST +01:00=>8844, Sun, 01 Dec 2019 00:00:00.000000000 GMT +00:00=>3827}
```

## Adjust the neighbourhood model

If you are adding a new ONS dataset (currently May 2023) you _MUST_ change the value in `/app/models/neighbourhood.rb`! Which looks something like

```ruby
# frozen_string_literal: true

class Neighbourhood < ApplicationRecord
  # WARNING: this must be updated for every new ONS dataset
  #    see /lib/tasks/neighbourhoods.rake
  LATEST_RELEASE_DATE = DateTime.new(2023, 5).freeze  <----

  ...
```

## Deploying

The new dataset file and modified script/model must be commited to the repo and merged on to main when it comes to updating staging or production. Warning: between the time that your new code has been deployed to staging/production and the time the new import script has been run nobody will be able to select any neighbourhoods (as your updates will be filtering for the latest neighbourhoods which you have not inserted yet).

## Fin

Congratulations, neighbourhoods should now be up to date.
