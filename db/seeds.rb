# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#

#Create Partners

#Hulme Community Garden Centre - Hulme Community Garden Centre
hcgc_address = Address.create(street_address: '28 Old Birley Street', city: 'Manchester', postcode: 'M15 5RG')
hcgc         = Partner.create(name: 'Hulme Community Garden Centre', address: hcgc_address)
hcgc_place   = Place.create(name: 'Hulme Community Garden Centre', address: hcgc_address )

hcgc.places << hcgc_place

Calendar.create(name: 'HCGC Big Events',
                type: :facebook,
                partner_id: hcgc.id,
                place_id: hcgc_place.id,
                source: 'HulmeCommunityGardenCentre')


#Big Life Centres - Zion Centre & Kath Locke Centre
zion_address     = Address.create(street_address: '339 Stretford Road', city: 'Manchester', postcode: 'M154ZY')
kath_address     = Address.create(street_address: '123 Moss Lane East', city: 'Manchester', postcode: 'M155DD')

blc              = Partner.create(name: 'Big Life Centres')
zion_place       = Place.create(name: 'Zion Centre', address: zion_address)
kath_locke_place = Place.create(name: 'Kath Locke Centre', address: kath_address)
blc.places << zion_place << kath_locke_place

Calendar.create(name: 'Zion Centre Guide',
                type: :outlook,
                partner_id: blc.id,
                place_id: zion_place.id,
                source: 'https://outlook.office365.com/owa/calendar/51588529b2f24206a4b1098e837159c7@thebiglifegroup.com/9d568b127b2c4760b726aff87e3ddaca9265853961212541948/calendar.ics')

Calendar.create(name: 'Kath Locke Centre Guide',
                type: :outlook,
                partner_id: blc.id,
                place_id: kath_locke_place.id,
                source: 'https://outlook.office365.com/owa/calendar/51588529b2f24206a4b1098e837159c7@thebiglifegroup.com/9d568b127b2c4760b726aff87e3ddaca9265853961212541948/calendar.ics')

#Red Bricks - Bentley House TARA Office
bentley_address = Address.create(street_address: '26 Humberstone Ave', city: 'Manchester', postcode: 'M155FD')
red_bricks      = Partner.create(name: 'Red Bricks')
bentley_place   = Place.create(name: 'Bentley House TARA Office', address: bentley_address)
red_bricks.places << bentley_place

Calendar.create(name: "Red Bricks What's On",
                type: :other,
                partner_id: red_bricks.id,
                place_id: bentley_place.id,
                source: 'https://www.redbricks.org/events/')

#Afro-Carribbean Care Group (ACCG) - ACCG Centre
accg_address      = Address.create(street_address: 'Rolls Crescent', city: 'Manchester', postcode: 'M15 5FS')
african_caribbean = Partner.create(name: 'Afro-Carribbean Care Group (ACCG)')
accg_place        = Place.create(name: 'ACCG Centre', address: accg_address)
Calendar.create(name: 'African Caribbean Care Group',
                type: :outlook,
                partner_id: african_caribbean.id,
                place_id: accg_place.id,
                source: 'https://outlook.office365.com/owa/calendar/53862ba33d814e8a8ca983ebbf796fee@accg.org.uk/c4100179b7ca49a88916b4a1c41de9fd686060547943940178/calendar.ics')

#Old Abbey Taphouse - Old Abbey Taphouse
abbey_address        = Address.create(street_address: 'Guildhall Close', city: 'Manchester', postcode: 'M15 6SY')
abbey_taphouse       = Partner.create(name: 'Old Abbey Taphouse')
abbey_taphouse_place = Place.create(name: 'Old Abbey Taphouse', address: abbey_address)

Calendar.create(name: 'Old Abbey Taphouse',
                type: :facebook,
                partner_id: abbey_taphouse.id,
                place_id: abbey_taphouse_place.id,
                source: 'abbeyinnmcr')

#Hulme & Moss Side Age Friendly Events
hulme_moss = Partner.create(name: 'Hulme & Moss Side Age Friendly Events')

Calendar.create(name: 'Hulme & Moss Side Age Friendly Events',
                type: :google,
                partner_id: hulme_moss.id,
                source: 'https://calendar.google.com/calendar/ical/d0ok3oc2trd21adadm3b8qaimg%40group.calendar.google.com/public/basic.ics')

