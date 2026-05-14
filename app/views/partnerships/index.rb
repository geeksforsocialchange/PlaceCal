# frozen_string_literal: true

# TODO(#3163): Move to app/directory/views/partnerships/index.rb
class Views::Partnerships::Index < Views::Base
  prop :partnerships, _Interface(:each)
  prop :site, _Nilable(::Site), default: nil

  def view_template
    content_for(:title) { 'Partnerships' }

    Hero('Partnerships', "#{@partnerships.count} community hubs running on PlaceCal")

    div(class: 'c') do
      div(class: 'grid md:grid-cols-2 lg:grid-cols-3 gap-4 py-8') do
        @partnerships.each do |partnership|
          DirectoryPartnershipCard(partnership: partnership)
        end
      end
    end
  end
end
