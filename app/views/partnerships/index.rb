# frozen_string_literal: true

class Views::Partnerships::Index < Views::Base
  prop :partnerships, _Interface(:each), reader: :private
  prop :site, Site, reader: :private

  def view_template
    content_for(:title) { 'Partnerships' }
    content_for(:image) { site.og_image }
    content_for(:description) { 'All partnerships on PlaceCal' }

    Hero('Partnerships', site.tagline)
    div(class: 'c c--lg-space-after') do
      Breadcrumb(trail: [['Partnerships', partnerships_path]], site_name: site.name)

      hr

      ul(class: 'partners reset two-col') do
        partnerships.each do |partnership|
          PartnershipPreview(
            partnership: partnership,
            partner_count: partner_counts[partnership.id] || 0
          )
        end
      end
    end
  end

  private

  def partner_counts
    @partner_counts ||= ::PartnerTag
                        .joins(:partner)
                        .where(partners: { hidden: false })
                        .joins(:tag)
                        .where(tags: { type: 'Partnership' })
                        .group(:tag_id)
                        .count
  end
end
