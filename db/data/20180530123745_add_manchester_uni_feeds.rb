class AddManchesterUniFeeds < SeedMigration::Migration
  def up
    partner = Partner.create!(name: "Manchester University")
    places = Place.create(places(partner.id))
  end

  def down
    partner = Partner.find_by(name: "Manchester University")
    partner.places.destroy_all
    partner.destroy
  end

  def places(partner_id)
    [
      {
        name: "Manchester Museum",
        calendars_attributes: [
          {
            name: "Manchester Museum",
            source:
              "http://events.manchester.ac.uk/f3vf/calendar/tag:manchester_museum/view:list/p:q_details/calml.xml",
            strategy: "place",
            type: "manchesteru",
            partner_id: partner_id
          }
        ],
        address_attributes: {
          street_address: "The University of Manchester",
          street_address2: "Oxford Road",
          city: "Manchester",
          postcode: "M13 9PL",
          country_code: "UK"
        }
      },
      {
        name: "The Whitworth",
        calendars_attributes: [
          {
            name: "The Whitworth",
            source:
              "http://events.manchester.ac.uk/f3vf/calendar/tag:whitworth/view:list/p:q_details/calml.xml",
            strategy: "place",
            type: "manchesteru",
            partner_id: partner_id
          }
        ],
        address_attributes: {
          street_address: "The University of Manchester",
          street_address2: "Oxford Road",
          city: "Manchester",
          postcode: "M15 6ER",
          country_code: "UK"
        }
      },
      {
        name: "Martin Harris Centre",
        calendars_attributes: [
          {
            name: "Martin Harris Centre",
            source:
              "http://events.manchester.ac.uk/f3vf/calendar/tag:martin_harris_centre/view:list/p:q_details/calml.xml",
            strategy: "place",
            type: "manchesteru",
            partner_id: partner_id
          }
        ],
        address_attributes: {
          street_address: "The University of Manchester",
          street_address2: "Bridgeford Street, off Oxford Road",
          city: "Manchester",
          postcode: "M13 9PL",
          country_code: "UK"
        }
      },
      {
        name: "John Rylands Library",
        calendars_attributes: [
          {
            name: "John Rylands Library",
            source:
              "http://events.manchester.ac.uk/f3vf/calendar/tag:john_rylands_library/view:list/p:q_details/calml.xml",
            strategy: "place",
            type: "manchesteru",
            partner_id: partner_id
          }
        ],
        address_attributes: {
          street_address: "150 Deansgate",
          city: "Manchester",
          postcode: "M3 3EH",
          country_code: "UK"
        }
      }
    ]
  end
end
