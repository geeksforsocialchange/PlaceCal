class AddPlacesPartners < SeedMigration::Migration
  def up
    # Hulme Garden Centre
    hcgc_address =
      Address.create(
        street_address: "28 Old Birley Street",
        city: "Manchester",
        postcode: "M15 5RG"
      )
    hcgc =
      Partner.create(
        name: "Hulme Community Garden Centre",
        address: hcgc_address,
        public_email: "info@hulmegardencentre.org.uk",
        short_description:
          "A garden centre with a difference that makes a difference!

      Hulme Community Garden Centre is a unique community led inner-city horticultural project and charity. Our mission is to bring the local community together through gardening.

      As a not-for-profit organisation we provide low-cost plants to the local community but we are foremost a volunteer and education hub promoting horticultural and sustainability issues to schools, colleges, the local community and wider public."
      )
    hcgc.places << Place.create(
      name: "Hulme Community Garden Centre",
      short_description:
        "A garden centre with a difference that makes a difference!",
      address: hcgc_address
    )
    # Zion Centre
    blc =
      Partner.create(
        name: "Big Life Centres",
        short_description:
          "Big Life Centres enables people to live their best lives. It does this by developing health and well being centres that deliver holistic services to improve the quality of life for people living in disadvantaged areas. It enables people to make choices for themselves.

      Big Life Centres offer:

       * A place in the community – high quality, welcoming, helpful
       * Improving access to health and wellbeing services for all residents
       * Supporting people and providing opportunities for them to achieve their goals and aspirations
       * Offering tenants a high quality, competitive service with added value linked to our shared values
       * Improving health and wellbeing outcomes"
      )
    blc.places << Place.create(
      name: "Zion Community Resource Centre",
      phone: "0161 226 5412",
      url: "https://www.thebiglifegroup.com/big-life-centres/zion-centre/",
      address:
        Address.create(
          street_address: "339 Stretford Road",
          city: "Manchester",
          postcode: "M154ZY"
        )
    )
    blc.places << Place.create(
      name: "Kath Locke Centre",
      phone: "0161 455 0211",
      short_description:
        "The Kath Locke Centre combines the best in conventional NHS healthcare alongside complementary therapies to offer a complete approach to health and well-being.",
      url:
        "https://www.thebiglifegroup.com/big-life-centres/kath-locke-centre/",
      address:
        Address.create(
          street_address: "123 Moss Lane East",
          city: "Manchester",
          postcode: "M155DD"
        )
    )
  end

  def down
    # Prob don't need this
    # ["Hulme Community Garden Centre"].each { |p| Partner.where(name: p).destroy_all }
  end
end
