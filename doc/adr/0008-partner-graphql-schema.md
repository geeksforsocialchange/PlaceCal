# **Q1. How do we want Trans Dimension, and by extension, other sites based on the PlaceCal API, to query the API?**

### **A1.1. Query a Site → Configured in PlaceCal Sites interface.**

[london.placecal.org](http://london.placecal.org) → transdimension.placecal.org. We add in a tag filter to the site and then the API infers everything from here

1. Get Site with ID X
2. Get Partners and Events and Articles inside that site

Pros: User configurable, understantable in the UI, easier to charge for

Cons: Inflexible - can’t have API different to Site

```graphql
site(id: 5) {
	allPartners {
		summary
		description
		allEvents {
			summary
			description
			dtstart
		}
	}
}
```

### **A1.2. Query by Tag and Location (chosen route)**

1. Get Partners that have Tag “The Trans Dimension” and are in location “London”
2. Ditto Events and Articlesand its like

```graphql
allPartners(with_tag: 12, inside_neighbourhood: 12314) {
	@type: Organization
	name (from model)
	summary
	description
	accessibilitySummary (accessibility_info)
	placecalID (link to placecal site)
	logo (from image they uploaded to placecal)
	address {
		@type: PostalAddress
		streetAddress (lines 1-3)
		addressLocality (ward from neighbourhood)
		addressRegion (district from neighbourhood)
		addressCountry (from country code)
		postalCode (from postcode)
		neighbourhood {
			@type: AdministrativeArea
			placecalID
			firstHalfOfPostcode (not done yet)
			shortName (our abbreviation for it)
			containedInPlace
			containsPlace
		}
	}
	url
	facebookPage
	twitterHandle
	areasServed (from service_areas) {
		[
      (these fields come from neighbourhood)
			name
			abbreviatedName
			unit
			unitName
			unitCodeKey
			unitCodeValue
    ],
		[],
		[]
	}
	contact {
		@type: ContactPoint
		name (from partner)
		email (from partner)
		telephone (from partner.public_phone)
	}
	openingHours {
		@type: OpeningHours
	}

}

// Sorted from current date in date order
allEvents(partner_id: id) {
	@type: Event
	name (summary)
	description
	startDate
	endDate
	placecalID
	location (PostalAddress, what placecal thinks the address is)
	organizer (Partner)
}
```

[https://schema.org/Organization](https://schema.org/Organization)

[https://schema.org/AdministrativeArea](https://schema.org/AdministrativeArea)

[https://schema.org/PostalAddress](https://schema.org/PostalAddress)

[https://schema.org/openingHours](https://schema.org/openingHours)

[https://schema.org/Event](https://schema.org/Event)

Pros: Way more flexible for developers, simpler queries

Cons: Harder to keep track of what developers are doing, not visible in the PlaceCal UI for non-technical users
