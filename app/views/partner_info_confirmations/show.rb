# frozen_string_literal: true

class Views::PartnerInfoConfirmations::Show < Views::Base
  include Phlex::Rails::Helpers::SubmitTag

  prop :user, User, reader: :private
  prop :token, String, reader: :private

  def view_template
    content_for(:title) { t('partner_info_confirmations.show.title') }

    Directory::PageHero(
      title: t('partner_info_confirmations.show.title'),
      breadcrumb_label: t('partner_info_confirmations.show.title')
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose-lg) mx-auto') do
        p(class: 'mb-4') { t('partner_info_confirmations.show.intro') }

        ul(class: 'list-disc pl-6 mb-6 space-y-1') do
          user.partners.order(:name).each do |partner|
            li { partner.name }
          end
        end

        form_tag(partner_info_confirmation_path, method: :post) do
          raw hidden_field_tag(:token, token)
          raw submit_tag(t('partner_info_confirmations.show.button'),
                         class: 'bg-foreground text-background rounded-full px-6 py-3 text-sm font-bold border-0 cursor-pointer hover:bg-tertiary transition-colors')
        end
      end
    end
  end
end
