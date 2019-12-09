# Create secretary permissions

* Deciders: kimadactl
* Date: 2019-12-09

## Background

PlaceCal has a ward-based admin structure that is designed to map onto the "real world" politics of public health, housing, neighbourhood teams, etc. This means that we give groups power over named wards.

So far, the only role in use for administration has been 'root' - meaning everyone can access everything. This is obviously pretty bad for security and means that new secretaries will be blinded with more information than they need.

This patch needs to find a way to assign permissions to secretaries in a way that balances the risk of frustratingly locking them out of neighbouring wards they might not know events are in with the security and sprawl needs above.

## Solution 1 - granular (chosen option)

### Sites - OK

For now, use the site admin to denote the secretary. Later on we will need to add additional users as site secretaries.

Lock out the "main neighbourhood" and "other neighbourhoods to include" from being edited by the secretary. Instead show this as plain text/info. This list of wards will be an important thing for each user and the main way we will identify permissions in this process. Call it a 'patch'? The root admin will set this.

Is there any way we can programatically find all surrounding wards and create these at inception?

 * Create - no
 * Read - their own sites
 * Update - their own sites (apart from neighbourhoods fields as mentioned)
 * Delete - no

### Partners

Partners all have a primary ward. If the secretary is admin of a site that contains this ward, they can edit it.

* CRUD - partners in their area
* Create - ideally would be asking for name, postcode first - pass off as duplicate checker?

### Calendars - importing

This is a tough one: options? Risk of malicious events being added from out of area.

 1. Strict: Check each event is within the region specified by the site, if it's not in it reject and list an error
 2. Permissive: Let people import what they want, this is a low security risk for now

 * If address matches partner in the area, list it, if it matches a partner in another area, don't and flag error
 * Ditto for place

### Calendars - CRUDing

We currently have no connection between calendars and wards directly. Ideas

1. Every calendar needs a partner, place or both. This then gives something to latch on to.
2. Calendars are listed as in wards? This might solve another problem we have in terms of listing events that don't have an address.

* CRUD - must have a partner or place or both in the secretary's scope that will show up in the dropdowns

### Users

 * CRU accounts that edit partners in their area
 * D - no

### Key difficulties

 * Finding adjacent wards to the primary site
 * Events and calendars outside the target area
 * Who really owns calendars?


## Option 2 - larger areas

At some point we will want to be able to create city regions probably such as Manchester, Berwickshire. Maybe we do this now and actually these secretaries are just "ruling" over the Manchester part of the site and the other ones don't touch?

Presumes people get on with other people they live nearby and would eventually cause issues for border areas of PlaceCal installations - maybe a good problem to have?

Feels like this route takes a lot more thought to do properly. Rejected but review later.
