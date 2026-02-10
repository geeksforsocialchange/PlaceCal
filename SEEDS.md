# Seeds

Running `bin/setup` or `bin/rails db:seed` populates the database with realistic development data using the Normal Island fictional geography. Seeds are **idempotent** (safe to re-run) and **additive** (layer alongside existing data, e.g. after cloning a production database).

## What gets created

- **Neighbourhoods**: Full Normal Island hierarchy (country, 2 regions, 2 counties, 3 districts, 8 wards)
- **Tags**: 21 categories (e.g. Health & Wellbeing, Food, LGBTQ+, Arts & Culture), 4 facilities, 3 partnerships
- **Sites**: 4 published sites — 3 at different geographic levels (country, county, district) and 1 partnership site (Normal Island Book Clubs) — each with hero images, logos, and themes. Plus one unpublished default site.
- **Users**: 9 users covering every admin role, with avatars (see table below). All passwords are `password`.
- **Partners**: ~100 partners across all 8 wards, each with address, categories, social media links, opening times, phone numbers, and images
- **Events**: 600+ events per partner (mix of past and future dates) with 50 different event types

## Seed users

| Email                                 | Role                | Scope                   |
| ------------------------------------- | ------------------- | ----------------------- |
| root@placecal.org                     | Root                | Everything              |
| editor@placecal.org                   | Editor              | All news articles       |
| neighbourhood-admin@placecal.org      | Neighbourhood admin | Millbrook district      |
| partner-admin@placecal.org            | Partner admin       | Riverside Community Hub |
| site-admin-normal-island@placecal.org | Site admin          | Normal Island site      |
| site-admin-coastshire@placecal.org    | Site admin          | Coastshire site         |
| site-admin-millbrook@placecal.org     | Site admin          | Millbrook site          |
| site-admin-book-clubs@placecal.org    | Site admin          | Book Clubs site         |
| citizen@placecal.org                  | Citizen             | No admin access         |

## Sites in development

After seeding, these sites are available:

| Site                     | URL                              | Type        |
| ------------------------ | -------------------------------- | ----------- |
| Normal Island            | http://normal-island.lvh.me:3000 | Country     |
| Coastshire               | http://coastshire.lvh.me:3000    | County      |
| Millbrook                | http://millbrook.lvh.me:3000     | District    |
| Normal Island Book Clubs | http://book-clubs.lvh.me:3000    | Partnership |
| Admin                    | http://admin.lvh.me:3000         | —           |

## Normal Island

Tests and seeds use a fictional geography called "Normal Island" (country code: ZZ, a user-assigned ISO 3166 code) to avoid conflicts with real UK data. See `lib/normal_island.rb` for the full data structure and `doc/testing-guide.md` for guidance on writing tests.

The geography hierarchy:

```
Country: Normal Island (ZZ)
├── Region: Northvale
│   └── County: Greater Millbrook
│       ├── District: Millbrook
│       │   ├── Ward: Riverside
│       │   ├── Ward: Oldtown
│       │   ├── Ward: Greenfield
│       │   └── Ward: Harbourside
│       └── District: Ashdale
│           ├── Ward: Hillcrest
│           └── Ward: Valleyview
└── Region: Southmere
    └── County: Coastshire
        └── District: Seaview
            ├── Ward: Cliffside
            └── Ward: Beachfront
```

## Geocoding

Seeds use a custom geocoder lookup (`Geocoder::Lookup::NormalIsland`) that handles Normal Island's ZZ-prefix postcodes locally without hitting any external API. Real UK postcodes are delegated to postcodes.io as normal. This lookup is active in all environments, so Normal Island data works in development, test, and even alongside real UK data in production.

The lookup lives at `lib/normal_island/geocoder_lookup.rb` and is registered in `config/initializers/geocoder.rb`.
