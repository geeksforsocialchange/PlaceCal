# app/components/place/place_component.rb
class PlaceComponent < MountainView::Presenter
  properties :name, :logo, :home, :opening_times,
             :short_description, :booking_info, :context

  def page?
    properties[:context] == :page
  end

end
