# Restructuring application

## Background

Places and Partners have similar fields and instances of these often have the same name for a Partner and its associated Place. This has several implications.

- For citizens, Partners and Places are ways of viewing both local offers and the sets of events that those Places/Partners organise.
- For secretaries and admins, Partners and Places both require seperate information maintenance and the difference between the two is not crystal clear.
- For developers, models that have a relationships with Partners will also have an indirect relationship with Places and vice versa. This is making the permission system somewhat opaque.

Making further changes to the application is therefore percieved as time consuming, because adding or modifying anything that relates to Partner means adding/modifying for Place too.

Q: What are the specific areas of code (i.e. files, methods) where duplication currently manifests? Very specific identification of problem areas might suggest different approaches.

A: These are not currently active, but theoretically the following should all overlap:

- Name, description, logo, map
- Contact information for the general public, for us to contact admins, for us to contact managers
- Address
- Opening times
- Associations with Users
- Associations with Sites
- Associations with Turfs
- Associations with Calendars

## A note on independence of different layers

Developers discussing the restructuring have mentioned multiple parts of the system:

- The strategy/social layer: social and legal implementation details between commissioners and the site itself (i.e., the management outside the site)
- The user interface for citizens
- The user interface for admins and secretaries
- The underlying software models

Each layer can have its own nomenclature and granularity. Although it would probably be counter-productive to give the site-visitor UI different nomenclature from the admin UI, in all other respects these layers can be independent in their language. Avoiding real-world naming might be useful in order to shed assumptions that come with a real-world name. UI can evolve quickly if it does not need to stick to the naming and granularity used in the underlying models.

## Possible restructuring approaches

1.  Apply the solution detailed in ADR 0001-combine-places-and-partners.
1.  Refactor the underlying model for a cleaner set of abstractions (tentatively described below.)
1.  Redevelop the admin UI for smoother UX independently of any refactoring of the models.

## Cleaning abstractions

It may be that moving some data around between models could change their roles within the software system. This is my view of the roles played by models. Names are not necessarily in direct correspondence with the current architecture:

- Partner - a real-world organisation that is a collaborator in PlaceCal
- Event - a real-world event
- Location - a human-readable identifier for somewhere at which events take place. In addition, it may be useful for a Partner to have a Location if the Partner organisation needs to be physically interacted with, other than at Events.
- Place - some extra information about a location. Not all locations necessarily require this extra information. Opening times and accessibility features may be useful. A Partner who manages the given location may also be useful.

### Issues with this current abstraction

There are currently several problems with this. (will keep adding when I think of them)

"Partner" specifically refers to someone inside the PlaceCal partnership in the real world: ideally an organisation actively taking part in age friendly activities (in our case). There is currently no way to show other organisations who might be active locally, but are either not in the partnership (i.e. we are updating their events for them) or simply don't wish to be seen as partners.

Partners and Places in the real world very often have almost no difference. I estimate in 90% of cases Places are also Partners. This is the main place that the distinction falls down.
