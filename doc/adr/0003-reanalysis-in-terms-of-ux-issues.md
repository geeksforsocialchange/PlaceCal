# An analysis of some PlaceCal UX issues

This is my (Justin's) impression of the current issues with PlaceCal as I understand them after meeting Kim and Gabriela on Tue 16th July. Issues are split between the public (citizen) interface and the admin interface. Possible solutions to these issues are outlined.

## Public interface

### Partner & Place with same name

The split of a Place and Partner across two pages, when the Place is the location of the Partner and they both have the same name, has great potential for confusion:

- Each page shows different kinds of information that depends on a context that may not be obvious to the viewer.
- Each page also shows an events list but the lists are generated in different ways and may have different items.
- Either page could effectively become a defacto landing page via a search engine. Default views may therefore become inconsistent across different organisations.

The distinction between the two contexts (who? and where?) does not have a strong justification at the UI level.

**Proposed solution**:

- Combine the "who?" and the "where?" into a single view when appropriate. If the admin interface guides admins to add organisational and location data together then we can link these two DB entites behind the scenes. The super-admin interface would still allow us to manually edit this info.
- Pick a sensible default way of generating the events list for the combined view and allow people to change this manually. (Organised by, Hosted at, logical OR, logical AND.)

### Relationship visibility

Stakeholders and potential stakeholders currently have no way of seeing the relationships bewteent the various organisational and spatial entities in the system. This is a lack of potentially useful information:

- What venues does has this organisation held events at in the last 6 months?
- What projects are managed by this organisation?
- What organisations held events here in the last 6 months?
- What organisations are co-located here?

**Proposed solutions**:

- Add a way to record relationships between organisations and show these relationships to site visitors.
- Use stored events to determine and show organisation-location relationships.

### "Placeholder" information appearing on the website

We are keen to maintain the current flexibility with respect to allowing admins to add incomplete information about entities and still have those entities appear on the website, however this does create a quality issue. For instance, we currently display "placeholder" entities if the only information for that entity is a title.

Adding mandatory fields in the admin interface is not an option. We cannot presume in advance to know _what_ information will be available.

**Proposed solution**: Automatically determine whether an entity has sufficient information to presented on the website. This could be done at edit-time (stored status) or display-time (calculated just-in-time). Filter views based on sufficiency of information.

### Lack of clarity about information status

Information on the site about organisations and locations has come from different sources. Stakeholders and potential stakeholders currently recieve no cues about how accurate and up-to-date such information is. It may be useful to provide some cues.

**Proposed solution**: Add a status to entities that describes how the information is obtained, e.g.

- Supplied by a 3rd party.
- Obtained in a one-off collaboration with the relevant organisation.
- Directly managed and updated by the relevant organisation.

This should be easy to add to admin workflows. Also, editing by users who are known to be members of given organisations could be recorded without requesting this info from the editor. (Direct edits through the super-admin interface could be supported for technical users.)

We could also display the date that information was last edited and optionally by who.

## Admin interface

### Entity focussed rather than task focussed interface

The "home" page of the admin interface is a list of entities. The main navigation links are the names of entity types and their target pages include the option to create a new entity of the relevant type.

This interface is close to a literal interpretation of the model schema. It does not guide admins who have no need to understand the finer distictions between different kinds of entity.

**Proposed soltution**: Provide a list of tasks to accomplish on the admin home screen. Have these tasks lead to multi-page forms in order to keep the total amount of information on a page low, and to segue smoothly through different contexts (e.g. combained Partner/Place). Use vernacular cues, e.g. progress display along the top of a multi-page form. On submission, provide logical follow-up options and an option to return to the home page, i.e. to the original list of tasks.

### Insufficient distinction between Partner and Place

At the moment, the admin interface requires admins to understand the difference between a Partner and a Place and to create/edit one or both of these entities for a given organisation.

This need for understanding about DB-level entities can be ameliorated to a large degree by implementing a more task-oriented UI (above). We could do more than this too.

**Proposed solutions**: We discussed solutions for this but I think they could be implemented to different depths.

1.  Shallow approach: Use language within the admin UI to make the distinction more obvious. This may mean talking about "organisations" and "locations" (rather than partners and places) or there may be other terms that are better suited. We would need to test these on users.

2.  Deeper approach: Make an explicit progression from
    - organisation to Partner, and
    - address to Place.

The progression (rather than just the language) and the need to promote entities may link the Partners and Places in a firmer way to more obvious primitives.

### Potential duplication in entering contacts

Some entities have multiple "slots" for contact details. These slots may require duplication of content (same person as contact in multiple contexts) and limit each kind of contact to one set of contact details.

**Proposed solution**: Allow addition of unlimited contacts. Give facility to tag contacts with roles. This allows, e.g. multiple contacts to recieve notice that a given entity has been updated in PlaceCal, and the same contact to be used for multiple roles with greater chance of consistency and lower chance of entry errors.
