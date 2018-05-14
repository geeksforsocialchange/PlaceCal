module PartnersHelper
  def options_for_partners
    Partner.all.collect { |p| [p.name, p.id ]}
  end
end
