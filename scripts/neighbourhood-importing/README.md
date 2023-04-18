# Neighbourhood Importing

Importing neighbourhood data is nontrivial and involves a fair amount of customisation.

1. Download ONS geo data

2. Modify extraction script to create importable neighbourhood payload

3. Run rake task to import neighbourhood payload


## Backup neighbourhood table

Backup the neighbourhood table with `rails placecal:backup_neighbourhood_table`.


## Download data

Visit here and find latest dataset https://geoportal.statistics.gov.uk/search?collection=Dataset

Should look something like https://geoportal.statistics.gov.uk/datasets/9ac0331178b0435e839f62f41cc61c16/about

Save and extract to a folder (reffered here as `ONS_DATA_DIR`).

## Extraction

The ONS data comes in many CSVs that contain a lot of information that we don't use.

There is a script called `prepare-neighbourhood-payload.rb` that will extract what we need.

Warning! The structure of these CSVs may have changed and broken the script.

Open up the script and modify the configuration at the end to point to `ONS_DATA_DIR`. You may also need to change some of the filenames.

When you run the script it will generate a `neighbourhoods.json` output file.

## Importing

DANGER! this will destroy your neighbourhoods table. backup beforehand with `rails placecal:save_neighbourhoods`.

Now change directory to the placecal root folder and run `rails placecal:import_neighbourhoods[path/to/neighbourhoods.json]`

This will:

- make a note of all the postcodes in the address table
- delete all the neighbourhoods
- load the new neighbourhood data into the neighbourhood table
- look up all the postcodes and map them to ward codes
- link addresses to neighbourhoods based on postcode
