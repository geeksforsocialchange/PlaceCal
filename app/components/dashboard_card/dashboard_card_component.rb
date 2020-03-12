# frozen_string_literal: true

# app/components/card/card_component.rb
class DashboardCardComponent < MountainView::Presenter
  property :title, default: false
  property :subtitle, default: false
  property :image, default: false
  property :link, default: false
  property :last_updated, default: false

  def description
    if properties[:description]
      properties[:description].truncate(200)
    end
  end
end
