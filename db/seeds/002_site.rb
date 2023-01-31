# frozen_string_literal: true

Site.find_or_create_by!(
  slug: 'default-site'
) do |site|
  site.name = 'Normal Island'
  site.domain = "#{site.slug}.lvh.me"
end
