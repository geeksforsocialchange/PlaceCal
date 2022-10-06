Site.find_or_create_by!(
  slug: "default-site",
) do |site|
  site.name = "Normal Island"
  site.domain = "#{site.slug}.lvh.me"
end

Site.find_or_create_by!(
  slug: "north",
) do |site|
  site.name = "North of Normal"
  site.domain = "#{site.slug}.lvh.me"
end

Site.find_or_create_by!(
  slug: "south",
) do |site|
  site.name = "South of Normal"
  site.domain = "#{site.slug}.lvh.me"
end
