# frozen_string_literal: true

class AddDefaultSite < ActiveRecord::Migration[5.1]
  def up
    execute(
      %(insert into sites
(name, domain, slug, created_at, updated_at)
values
('Default site (no subdomain)', 'placecal.org', 'default-site', now(), now()) ;)
    )
  end

  def down
    execute(
      %(delete from sites_neighbourhoods where site_id =
(select id from sites where slug = 'default-site');)
    )
    execute("delete from sites where slug = 'default-site';")
  end
end
