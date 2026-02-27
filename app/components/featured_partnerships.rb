# frozen_string_literal: true

class Components::FeaturedPartnerships < Components::Base
  prop :sites, _Interface(:each) # Array or ActiveRecord relation

  def view_template
    div(class: 'featured_partnerships') do
      h3(class: 'featured_partnerships--title') { 'Curated Calendars' }
      FourColGrid(partnership_cards: true) do
        @sites.each do |site|
          PartnershipCard(site: site)
        end
      end
    end
  end
end
