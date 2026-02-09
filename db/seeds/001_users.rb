# frozen_string_literal: true

require_relative '../../lib/normal_island'

module SeedUsers
  def self.run
    $stdout.puts 'Users'

    NormalIsland::USERS.each do |_key, data|
      next if User.exists?(email: data[:email])

      User.create!(
        email: data[:email],
        password: 'password',
        password_confirmation: 'password',
        first_name: data[:first_name],
        last_name: data[:last_name],
        role: data[:role] || 'citizen'
      )
      $stdout.puts "  Created user: #{data[:first_name]} #{data[:last_name]} (#{data[:email]})"
    end
  end

  # Assign neighbourhood, partner, and site associations
  # Called from a later seed after those records exist
  def self.assign_associations
    NormalIsland::USERS.each do |_key, data|
      user = User.find_by(email: data[:email])
      next unless user

      if data[:neighbourhood]
        neighbourhood = Neighbourhood.find_by(name: data[:neighbourhood], unit: 'district')
        if neighbourhood && user.neighbourhoods.exclude?(neighbourhood)
          user.neighbourhoods << neighbourhood
          $stdout.puts "  Assigned #{user.email} as neighbourhood admin for #{neighbourhood.name}"
        end
      end

      if data[:partner]
        partner = Partner.find_by(name: data[:partner])
        if partner && user.partners.exclude?(partner)
          user.partners << partner
          $stdout.puts "  Assigned #{user.email} as partner admin for #{partner.name}"
        end
      end

      next unless data[:site]

      site = Site.find_by(slug: data[:site])
      if site && site.site_admin != user
        site.update!(site_admin: user)
        $stdout.puts "  Assigned #{user.email} as site admin for #{site.name}"
      end
    end
  end
end

SeedUsers.run
