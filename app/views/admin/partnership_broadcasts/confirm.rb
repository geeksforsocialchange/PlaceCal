# frozen_string_literal: true

class Views::Admin::PartnershipBroadcasts::Confirm < Views::Admin::Base
  include Phlex::Rails::Helpers::HiddenFieldTag
  include Phlex::Rails::Helpers::SubmitTag

  prop :broadcast, PartnershipBroadcast, reader: :private
  prop :recipients, BroadcastRecipientsQuery, reader: :private

  def view_template
    content_for(:title) { t('admin.partnership_broadcasts.confirm.title') }

    PageHeader(model_name: Partnership.model_name.human,
               title: t('admin.partnership_broadcasts.confirm.title'),
               id: broadcast.partnership.id)

    div(class: 'max-w-2xl space-y-6') do
      div(class: 'alert alert-warning') do
        p do
          t('admin.partnership_broadcasts.confirm.warning',
            people: recipients.eligible.size,
            partners: recipients.partners_count,
            partnership: broadcast.partnership.name)
        end
      end

      div(class: 'card bg-base-100 border border-base-300') do
        div(class: 'card-body') do
          h2(class: 'card-title') { broadcast.subject }
          p(class: 'whitespace-pre-line') { broadcast.body }
        end
      end

      if recipients.excluded_count.positive?
        p(class: 'text-sm text-gray-600') do
          t('admin.partnership_broadcasts.preview.excluded', count: recipients.excluded_count)
        end
      end

      div(class: 'flex items-center gap-4') do
        form_tag(admin_partnership_broadcasts_path(broadcast.partnership), method: :post) do
          raw hidden_field_tag('partnership_broadcast[subject]', broadcast.subject, id: nil)
          raw hidden_field_tag('partnership_broadcast[body]', broadcast.body, id: nil)
          raw hidden_field_tag(:confirmed, 'true', id: nil)
          raw submit_tag(t('admin.partnership_broadcasts.confirm.send_button', count: recipients.eligible.size),
                         class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange')
        end

        a(href: new_admin_partnership_broadcast_path(broadcast.partnership), class: 'btn btn-ghost') do
          t('admin.partnership_broadcasts.confirm.back')
        end
      end
    end
  end
end
