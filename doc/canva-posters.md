# Making event posters with Canva Bulk Create

PlaceCal can export any partner's upcoming events as a CSV file. Paired with
Canva's [Bulk Create](https://www.canva.com/help/bulk-create/) feature, this
lets a partner generate a poster (or social media graphic) for every one of
their events in a couple of minutes, from a shared template.

This is the MVP route chosen in
[issue #847](https://github.com/geeksforsocialchange/PlaceCal/issues/847):
Canva's Autofill API is Enterprise-only, but Bulk Create just needs a CSV and
a paid Canva plan — and [Canva for Nonprofits](https://www.canva.com/nonprofits/)
gives registered charities all the paid features for free.

## Getting the CSV

- On a partner's page, follow **Download events as CSV** (or request
  `/partners/<slug>.csv` directly).
- The file contains the partner's upcoming events, one row per event.

### Columns

| Header      | Contents                                        |
| ----------- | ----------------------------------------------- |
| Title       | Event name                                      |
| Date        | e.g. `1 Jan 2026`                               |
| Time        | e.g. `09:00 – 10:00`                            |
| Location    | Venue address (falls back to organiser address) |
| Organiser   | Partner name                                    |
| More info   | Link to the event's PlaceCal page               |
| Description | Event description, flattened to one line        |

The headers come from the `events.csv_export.headers` locale keys and the rows
are built in `app/services/events_csv.rb`. **Canva templates connect fields by
header name**, so renaming a header breaks existing templates — change both
together.

Everything is text: Canva Bulk Create does not fetch images from URLs in CSV
cells (it treats them as plain text), so the export deliberately contains no
image columns.

## Using it in Canva

1. Open the poster template (or make your own — any design with text
   placeholders works). Bulk Create needs a paid plan: Pro, Teams, Education,
   or the free-for-charities Nonprofits plan.
2. In the editor sidebar choose **Apps → Bulk Create**.
3. **Upload data** and pick the downloaded CSV.
4. Connect each text placeholder to a column: select the element, then
   **Connect data** and choose e.g. _Title_.
5. **Continue → Generate designs** — one poster per event (up to 300 rows per
   run).
6. Tweak individual posters as needed, then download or print.

## Shared PlaceCal template

We plan to maintain a shared PlaceCal poster template with fields already
connected to the CSV columns — link it here once it exists.
