# Restructuring application

## Background
Places and Partners have similar fields and instances of these often have the same name for a partner and its associated place. For site visitors, Partners and Places are both ways of viewing sets of events. For site admins Partners and Places both require information maintenance. For developers, models that have a relationships with Partner will also have a relationship with Place. (Q: Always?) Making further changes to the application is percieved as time consuming because adding or modifying anything that relates to Partner means adding/modifying for Place too.

Q: What are the specific areas of code (i.e. files, methods) where duplication currently manifests? Very specific identification of problem areas might suggest different approaches.

## A note on independence of different layers
Developers discussing the restructuring have mentioned multiple parts of the system:
 - The human-organisational layer
 - The user interface for site visitors
 - The user interface for site admins
 - The underlying software models
 
Each layer can have its own nomenclature and granularity. Although it would probably be counter-productive to give the site-visitor UI different nomenclature from the admin UI, in all other respects these layers can be independent in their language. Avoiding real-world naming might be useful in order to shed assumptions that come with a real-world name. UI can evolve quickly if it does not need to stick to the naming and granularity used in the underlying models.

## Possible restructuring approaches
0.  Apply the solution detailed in ADR 0001-combine-places-and-partners.
0.  Refactor the underlying model for a cleaner set of abstractions (tentatively described below.)
0.  Redevelop the admin UI for smoother UX independently of any refactoring of the models.

## Cleaning abstractions
It may be that moving some data around between models could change their roles within the software system. This is my view of the roles played by models. Names are not necessarily in direct correspondence with the current architecture:
 - Partner - a real-world organisation that is a collaborator in PlaceCal
 - Event - a real-world event
 - Location - a human-readable identifier for somewhere at which events take place. In addition, it may be useful for a Partner to have a Location if the Partner organisation needs to be physically interacted with, other than at Events.
 - Place - some extra information about a location. Not all locations necessarily require this extra information. Opening times and accessibility features may be useful. A Partner who manages the given location may also be useful.
 
 
