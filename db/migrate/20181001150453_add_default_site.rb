class AddDefaultSite < ActiveRecord::Migration[5.1]
  def up
    execute(
%(insert into sites
(name, domain, slug, created_at, updated_at)
values
('PlaceCal default site', 'placecal.org', 'placecal-default-site', now(), now()) ;)
    )
  end

  def down
    execute(
%(delete from sites_neighbourhoods where site_id =
(select id from sites where slug = 'placecal-default-site');)
    )
    execute( "delete from sites where slug = 'placecal-default-site';" )
  end
end
