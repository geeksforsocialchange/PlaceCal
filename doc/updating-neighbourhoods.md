# Updating neighbourhoods

## Background

PlaceCal maps postcodes to neighbourhoods using data from two sources:

1. **ONS (Office for National Statistics)** publishes CSV lookup files that define the hierarchy: ward → district → county → region → country. We import these into the `neighbourhoods` table.
2. **postcodes.io** maps postcodes to ONS ward/district codes at geocoding time.

When the ONS conducts boundary reviews (e.g. County Durham in March 2024, effective May 2025), postcodes.io adopts the new ward codes before we import them. This causes postcodes to return ward codes that don't exist in our database, resulting in the error "postcode has been found but could not be mapped to a neighbourhood at this time".

**Fallback matching:** Since v2024.05, `Neighbourhood.find_from_postcodesio_response` falls back to matching by `admin_district` code when a ward code isn't found. This means postcodes in redistricted areas will still resolve — to the district level — even before we import the new ward data.

## Full workflow checklist

1. Download new CSV from ONS → add to `lib/data/`
2. Update `lib/tasks/neighbourhoods.rake` with new `load_csv` call
3. Update `LATEST_RELEASE_DATE` in `app/models/neighbourhood.rb`
4. Run `rails neighbourhoods:import` locally and verify
5. Run `rails db:clean_bad_addresses` to prune orphaned addresses
6. Run `rails addresses:regeocode` to update stale address→neighbourhood links
7. Verify a specific postcode works (see Verification section)
8. Commit, merge, deploy
9. Run import + re-geocode on production

## Download new data

Check out the [ONS Open Geography Portal](https://geoportal.statistics.gov.uk/search?collection=Dataset&q=Ward%20to%20Local%20Authority%20District) and look for something titled like "Ward to Local Authority District to CTYUA to RGN to CTRY (May 2024) Lookup in the UK". Download and extract this into the PlaceCal repo in `/lib/data/`.

### Column name changes

The county column name changed in the May 2024 ONS data:

- **Pre-2024**: `CTY{YY}CD` / `CTY{YY}NM` — only contained shire counties (Lancashire, Norfolk). **Empty** for unitary authorities (County Durham, Bristol, etc.)
- **May 2024+**: `CTYUA{YY}CD` / `CTYUA{YY}NM` — includes both shire counties AND unitary authorities. For unitary authorities, the CTYUA code equals the LAD code (e.g. County Durham is `E06000047` at both levels).

When adding a new CSV with the `CTYUA` column, pass `county_prefix: 'CTYUA'` to `load_csv`:

```ruby
load_csv(
  DateTime.new(2024, 5),
  'Ward_to_Local_Authority_District_to_CTYUA_to_RGN_to_CTRY_(May_2024)_Lookup_in_the_UK.csv',
  county_prefix: 'CTYUA'
)
```

For unitary authorities, the CTYUA code equals the LAD code (e.g. Newcastle upon Tyne is `E08000021` at both levels). The rake task **skips the county row** when this happens, so the district row creates the entry with `unit: 'district'`. This is important because ward→district lookups and badge display depend on the parent being typed as `district`, not `county`.

## Perform the import

```bash
rails neighbourhoods:import
```

The import also backfills the integer `level` column for any records where it's nil (based on their `unit` string). This column is used by the admin cascading neighbourhood picker to filter by hierarchy level.

Verify the import by checking neighbourhood counts by release date:

```bash
rails runner "puts Neighbourhood.group(:release_date).count"
```

Example output:

```
{Mon, 01 May 2024 01:00:00 BST +01:00=>8845, Mon, 01 May 2023 01:00:00 BST +01:00=>8844, Sun, 01 Dec 2019 00:00:00 GMT +00:00=>3827}
```

## Update the neighbourhood model

Update `LATEST_RELEASE_DATE` in `/app/models/neighbourhood.rb` to match the new dataset:

```ruby
LATEST_RELEASE_DATE = DateTime.new(2024, 5).freeze
```

## Re-geocode stale addresses

After importing new neighbourhood data, existing addresses may still point to old neighbourhoods. Run:

```bash
# First, clean up orphaned addresses (not linked to any partner or event)
rails db:clean_bad_addresses

# Then re-geocode in-use addresses with stale neighbourhoods
rails addresses:regeocode
```

The re-geocode task finds addresses linked to partners or events that have either:

- No neighbourhood (`neighbourhood_id IS NULL`)
- A neighbourhood from an older release date

It re-queries postcodes.io for each and updates the neighbourhood link.

## Verification

Test that a specific postcode resolves correctly:

```bash
rails runner 'res = Geocoder.search("DH1 3EL").first.data; n = Neighbourhood.find_from_postcodesio_response(res); puts "#{n&.name} (#{n&.unit}) - #{n&.unit_code_value}"'
```

## Deploying

The new dataset file and modified script/model must be committed to the repo and merged to main. Then on production:

```bash
dokku run placecal rails neighbourhoods:import
dokku run placecal rails db:clean_bad_addresses
dokku run placecal rails addresses:regeocode
```

**Warning:** Between the time your new code is deployed and the import script runs, the `latest_release` scope will filter for the new release date which hasn't been imported yet. This means neighbourhood selection will be temporarily broken. Minimise this window by running the import immediately after deploy.
