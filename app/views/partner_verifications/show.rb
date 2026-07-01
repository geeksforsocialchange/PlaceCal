# frozen_string_literal: true

class Views::PartnerVerifications::Show < Views::Base
  include Phlex::Rails::Helpers::SubmitTag

  prop :partner, Partner, reader: :private
  prop :token, String, reader: :private

  def view_template
    content_for(:title) { t('partner_verifications.show.title', partner: partner.name) }

    Directory::PageHero(
      title: t('partner_verifications.show.title', partner: partner.name),
      breadcrumb_label: t('partner_verifications.show.breadcrumb')
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose-lg) mx-auto') do
        p(class: 'mb-4') { t('partner_verifications.show.intro', partner: partner.name) }
        p(class: 'mb-6') { t('partner_verifications.show.what_happens') }

        form_tag(partner_verification_path, method: :post) do
          raw hidden_field_tag(:token, token)
          raw submit_tag(t('partner_verifications.show.button', partner: partner.name),
                         class: 'bg-foreground text-background rounded-full px-6 py-3 text-sm font-bold border-0 cursor-pointer hover:bg-tertiary transition-colors')
        end
      end
    end
  end
end
