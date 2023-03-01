# frozen_string_literal: true

module PartnersHelper
  def options_for_service_area_neighbourhoods
    # Remove the primary neighbourhood from the list
    @all_neighbourhoods.filter { |e| e.name != '' }
                       .collect { |e| { name: e.contextual_name, id: e.id } }
  end

  def options_for_partner_tags
    policy_scope(Tag)
      .select(:name, :type, :id)
      .order(:name)
      .map { |r| [r.name_with_type, r.id] }
  end

  def partner_service_area_text(partner)
    neighbourhoods = partner.service_area_neighbourhoods.order(:name).all

    if neighbourhoods.length == 1
      neighbourhoods.first.name

    else
      head = neighbourhoods[0..-2]
      tail = neighbourhoods[-1]

      "#{head.map(&:name).join(', ')} and #{tail.name}"
    end
  end

  # Get a String containing a list of <a> tags for each service area related to
  # Partner, where the name is the Neighbourhood's name, and the URL is the
  # admin edit page for the Neighbourhood
  #
  # @param [Partner]
  # @return [String] HTML string
  def service_area_links(partner)
    partner.service_area_neighbourhoods
           .order(:name)
           .map { |hood| link_to hood.name, edit_admin_neighbourhood_path(hood) }
           .join(', ')
           .html_safe
  end

  # Get a String containing a list of <a> tags for each site,
  # where the name is the Site's name, and the URL is the site's domain
  #
  # @return [String] HTML string
  def site_links
    return unless @sites

    @sites.order(:name)
          .map { |site| link_to site.name, site.domain }
          .join(', ')
          .html_safe
  end
end
