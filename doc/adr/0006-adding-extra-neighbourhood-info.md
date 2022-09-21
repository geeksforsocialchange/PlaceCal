# Adding extra neighbourhood information

- Deciders: kimadactl
- Date: 2020-01-03

## Background

Expanding out PlaceCal means adding in extra place-based information and this makes it high time to review the place information added to the system.

On review this is a total mess. The ONS offer four different boundary maps depending on level of accuracy. These seem to change every year or so, in keeping with the constant restructuring in the UK.

- http://geoportal1-ons.opendata.arcgis.com/datasets/wards-may-2019-boundaries-uk-bsc
- http://geoportal1-ons.opendata.arcgis.com/datasets/wards-may-2019-boundaries-uk-bgc
- http://geoportal1-ons.opendata.arcgis.com/datasets/wards-may-2019-boundaries-uk-bfe
- http://geoportal1-ons.opendata.arcgis.com/datasets/wards-may-2019-boundaries-uk-bfc

After support with a very helpful person from ONS I discovered this list to corrolate ward with county etc. The column headings (`wd18nm`) refer to the year. This means that yes, every ward gets a new code each year, I think. For example, Hulme was `E05000706` and is now `E05011368`.

- https://geoportal.statistics.gov.uk/datasets/ward-to-local-authority-district-to-county-to-region-to-country-december-2018-lookup-in-united-kingdom-/data?page=6&selectedAttribute=LAD18NM

Since this I've been send a preliminary map for 2019 which shows big changes. Christchurch, the next area we are looking to expand to, has merged with two other areas (Bornmouth and Poole) in this time period.

Dumps of these files at the time of writing are in `../data/`.

## Going forwards

This is clearly going to be an ongoing work to complete and take a lot of thought on how to manage migrations. Some likely consequences are

- An annual review will be needed after boundary changes are published of every site and neighbourhood admin. This will cause an 'interesting' problem to migrate.
- Wards will need to be given a name chosen by people living locally. For example, "Christchurch, Bournemouth and Poole" is not where people are going to identify as living and we will need to decide which is which.
- Until we have some proper funding, we should probably only import the wards we need as opposed to all of them.

## Problem definition

1. I want to select a bunch of wards - probably using a spreadsheet and based on a `wd19cd` file. Check out `../data/starting_wards.xlsx` for this.
1. I want each one to join the data that postcodes.io returns below to this spreadsheet. This could possibly be done with the [ONS postcode directory](https://geoportal.statistics.gov.uk/datasets/ons-postcode-directory-november-2019). This is both a very large file and has all the info as lookup codes, though. This would be possible via postcodes.io if we had a lat/lng or postcode to latch on to, but we don't.
1. I want the final result to be made into a meaningful Rails seed.

Ideally, this whole thing would be done using the ONS APIs so that we don't have to mess about with CSV files.

## Notes

postcodes.io seems to have a little more info.

### BH1 2BZ (Bournemouth)

```
"result": {
 "postcode": "BH1 2BZ",
 "quality": 1,
 "eastings": 408965,
 "northings": 90999,
 "country": "England",
 "nhs_ha": "South West",
 "longitude": -1.874373,
 "latitude": 50.718551,
 "european_electoral_region": "South West",
 "primary_care_trust": "Bournemouth and Poole Teaching",
 "region": "South West",
 "lsoa": "Bournemouth 021A",
 "msoa": "Bournemouth 021",
 "incode": "2BZ",
 "outcode": "BH1",
 "parliamentary_constituency": "Bournemouth West",
 "admin_district": "Bournemouth, Christchurch and Poole",
 "parish": "Bournemouth, unparished area",
 "admin_county": null,
 "admin_ward": "Bournemouth Central",
 "ced": null,
 "ccg": "NHS Dorset",
 "nuts": "Bournemouth and Poole",
 "codes": {
     "admin_district": "E06000058",
     "admin_county": "E99999999",
     "admin_ward": "E05012653",
     "parish": "E43000226",
     "parliamentary_constituency": "E14000585",
     "ccg": "11J",
     "ccg_id": "11J",
     "ced": "E99999999",
     "nuts": "UKK21"
 }
```

### BH23 1PA (Christchurch)

```
"result": {
     "postcode": "BH23 1PA",
     "quality": 1,
     "eastings": 415467,
     "northings": 92960,
     "country": "England",
     "nhs_ha": "South West",
     "longitude": -1.782189,
     "latitude": 50.73605,
     "european_electoral_region": "South West",
     "primary_care_trust": "Dorset",
     "region": "South West",
     "lsoa": "Christchurch 006E",
     "msoa": "Christchurch 006",
     "incode": "1PA",
     "outcode": "BH23",
     "parliamentary_constituency": "Christchurch",
     "admin_district": "Bournemouth, Christchurch and Poole",
     "parish": "Christchurch, unparished area",
     "admin_county": null,
     "admin_ward": "Christchurch Town",
     "ced": "Christchurch Central",
     "ccg": "NHS Dorset",
     "nuts": "Dorset CC",
     "codes": {
         "admin_district": "E06000058",
         "admin_county": "E99999999",
         "admin_ward": "E05012658",
         "parish": "E43000053",
         "parliamentary_constituency": "E14000638",
         "ccg": "11J",
         "ccg_id": "11J",
         "ced": "E58000319",
         "nuts": "UKK22"
     }
 }
}
```
