# frozen_string_literal: true

class Views::Partnerships::Show < Views::Base
  prop :partnership, Partnership, reader: :private
  prop :partners, _Interface(:each), reader: :private
  prop :site, Site, reader: :private

  def view_template
    content_for(:title) { partnership.name }
    content_for(:image) { site.og_image }
    content_for(:description) { partnership.description || "Partners in the #{partnership.name} partnership" }

    Hero(partnership.name, site.tagline)
    div(class: 'c c--lg-space-after') do
      Breadcrumb(
        trail: [
          ['Partnerships', partnerships_path],
          [partnership.name, partnership_path(partnership)]
        ],
        site_name: site.name
      )

      hr

      render_description if partnership.description.present?
      render_subsites if partnership_sites.any?
      render_partners if partners.any?
    end
  end

  private

  def render_description
    div(class: 'partnership-description') do
      p { partnership.description }
    end
  end

  def render_subsites
    div(class: 'partnership-subsites') do
      h3 { 'Sites' }
      ul(class: 'reset') do
        partnership_sites.each do |s|
          li do
            link_to(s.name, s.url)
          end
        end
      end
    end
  end

  def render_partners
    div(class: 'partnership-partners') do
      h3 { "Partners (#{partners.size})" }
      ul(class: 'partners reset two-col') do
        partners.each do |partner|
          PartnerPreview(partner: partner, site: site)
        end
      end
    end
  end

  def partnership_sites
    @partnership_sites ||= partnership.sites.published
  end
end
