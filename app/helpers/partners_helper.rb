# frozen_string_literal: true

module PartnersHelper
  def options_for_service_area_neighbourhoods(for_partner)
    legacy_neighbourhoods = for_partner.service_area_neighbourhoods.where.not(release_date: Neighbourhood::LATEST_RELEASE_DATE)

    scope = Neighbourhood.find_latest_neighbourhoods_maybe_with_legacy_neighbourhoods(@all_neighbourhoods, legacy_neighbourhoods)

    scope
      .order(:name)
      .all
      .collect do |ward|
        name = ward.contextual_name
        name += " - #{ward.release_date.year}/#{ward.release_date.month}" if ward.legacy_neighbourhood?

        { name: name, id: ward.id }
      end
  end

  def options_for_partner_tags(partner = nil)
    options = policy_scope(Tag)
              .select(:name, :type, :id)
              .order(:name)
              .map { |r| [r.name_with_type, r.id] }
    return options unless partner

    (options + partner&.tags&.map { |r| [r.name_with_type, r.id] }).uniq
  end

  def permitted_options_for_partner_tags
    policy_scope(Tag).pluck(:id)
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
           .map { |hood| link_to_neighbourhood(hood) }
           .join(', ')
           .html_safe
  end

  # Get a String containing a list of <a> tags for each site,
  # where the name is the Site's name, and the URL is the site's url
  #
  # @return [String] HTML string
  def site_links
    return unless @sites

    @sites
      .map { |site| link_to site.name, site.url }
      .join(', ')
      .html_safe
  end

  def partner_has_unmappable_postcode?(partner)
    problems = partner.errors['address.postcode']
    return if problems.empty?

    problems.include? 'has been found but could not be mapped to a neighbourhood at this time'
  end
end
