# frozen_string_literal: true

class AddSupporterData < ActiveRecord::Migration[5.1]
  def up
    records.each do |r|
      if r[:logo]
        path = Rails.root.join('db/images/supporters', r[:logo])
        r[:logo] = Pathname.new(path).open
      end
      Supporter.where(name: r[:name]).first_or_create(r)
    end
  end

  def down
    records.each { |r| Supporter.where(name: r[:name]).destroy_all }
  end

  def records
    [
      {
        name: 'Geeks for Social Change',
        url: 'http://gfsc.studio',
        logo: 'gfsc.png',
        is_global: true,
        weight: 1
      },
      {
        name: 'PHASE@MMU',
        url: 'http://msaphase.org',
        logo: 'phase.png',
        is_global: true,
        weight: 2
      },
      {
        name: 'CityVerve',
        url: 'https://cityverve.org.uk/',
        logo: 'cityverve.png',
        is_global: true,
        weight: 3
      },
      {
        name: 'Manchester Metropolitan University',
        url: 'https://www2.mmu.ac.uk/',
        logo: 'mmu.png'
      },
      {
        name: 'Manchester City Council',
        url: 'http://www.manchester.gov.uk/',
        logo: 'mcc.png',
        is_global: true,
        weight: 4
      },
      {
        name: 'Age Friendly Hulme and Moss Side',
        url: 'http://mafn.org.uk/',
        logo: 'afhulme.png',
        weight: 1
      },
      {
        name: 'Buzz',
        description: 'Manchester Health and Wellbeing Service',
        url: 'https://buzzmanchester.co.uk/',
        logo: 'buzz.png',
        weight: 2
      },
      {
        name: 'People First Wellbeing Service',
        url: 'https://www.peoplefirstinfo.org.uk/health-and-well-being/',
        logo: 'people-first.png',
        weight: 3
      }
    ]
  end
end
