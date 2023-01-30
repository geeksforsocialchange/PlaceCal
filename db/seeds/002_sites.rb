
module SiteSeeder
  extend self

  def run
    site = Site.find_or_create_by!(slug: "default-site") do |site|
      site.name = "Normal Island"
      site.domain = "#{site.slug}.lvh.me"
    end
  end
end

SiteSeeder.run
