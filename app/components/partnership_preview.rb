# frozen_string_literal: true

class Components::PartnershipPreview < Components::Base
  prop :partnership, ::Partnership
  prop :partner_count, Integer, default: 0

  def view_template
    li(class: 'preview') do
      div(class: 'preview__header') do
        h3 { link_to(@partnership.name, partnership_path(@partnership), data: { turbo_frame: '_top', turbo_action: 'replace' }) }
        if @partner_count.positive?
          div(class: 'neighbourhood neighbourhood--primary preview__neighbourhood') do
            span { pluralize(@partner_count, 'partner') }
          end
        end
      end

      if @partnership.description.present?
        div(class: 'preview__details') do
          p { @partnership.description }
        end
      end
    end
  end
end
