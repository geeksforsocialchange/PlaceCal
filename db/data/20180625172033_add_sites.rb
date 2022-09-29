# frozen_string_literal: true

class AddSites < SeedMigration::Migration
  def up
    records.each do |r|
      r[:logo] = get_image(r[:logo])
      r[:footer_logo] = get_image(r[:footer_logo])
      r[:hero_image] = get_image(r[:hero_image])
      Site.where(name: r[:name]).first_or_create(r)
    end
  end

  def down
    records.each { |r| Site.where(name: r[:name]).destroy_all }
  end

  def get_image(path)
    full_path = Rails.root.join('db/images/sites', path)
    Pathname.new(full_path).open
  end

  def records # rubocop:disable Metrics/MethodLength
    [
      {
        name: 'Hulme',
        domain: 'hulme.placecal.org',
        slug: 'hulme',
        description: "PlaceCal Hulme is part of the Hulme and Moss Side Age Friendly Partnership, who are working to make Hulme a better place to be for over 50s. \n\nIf you're a local organisation and want to join our network, get in touch below. We provide training and support to help you publish your events.",
        site_admin_id: 1,
        logo: 'hulme-header.svg',
        footer_logo: 'hulme-footer.svg',
        hero_image: 'hulme-hero.jpg',
        hero_image_credit: 'Jane Samuels',
        supporters: Supporter.where(name: ['Age Friendly Hulme and Moss Side', 'Buzz',
                                           'People First Wellbeing Service'])
      },
      {
        name: 'Moss Side',
        domain: 'moss-side.placecal.org',
        slug: 'moss-side',
        description: "PlaceCal Moss Side is part of the Hulme and Moss Side Age Friendly Partnership, who are working to make Hulme a better place to be for over 50s. \n\nIf you're a local organisation and want to join our network, get in touch below. We provide training and support to help you publish your events.",
        site_admin_id: 1,
        logo: 'hulme-header.svg',
        footer_logo: 'hulme-footer.svg',
        hero_image: 'moss-side-hero.jpg',
        hero_image_credit: 'Jane Samuels',
        supporters: Supporter.where(name: ['Age Friendly Hulme and Moss Side', 'Buzz',
                                           'People First Wellbeing Service'])
      },
      {
        name: 'Rusholme',
        domain: 'rusholme.placecal.org',
        slug: 'rusholme',
        description: "PlaceCal Rusholme is part of the Hulme and Moss Side Age Friendly Partnership, who are working to make Hulme a better place to be for over 50s. \n\nIf you're a local organisation and want to join our network, get in touch below. We provide training and support to help you publish your events.",
        site_admin_id: 1,
        logo: 'hulme-header.svg',
        footer_logo: 'hulme-footer.svg',
        hero_image: 'rusholme-hero.jpg',
        hero_image_credit: 'Jane Samuels',
        supporters: Supporter.where(name: ['Trinity House', 'Buzz', 'People First Wellbeing Service'])
      }
    ]
  end
end
