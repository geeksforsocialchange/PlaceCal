module PlacesHelper

	def options_for_places
		Place.all.collect { |p| [p.name, p.id ]}
	end
end
