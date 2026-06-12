# frozen_string_literal: true

class Views::Admin::PartnershipBroadcasts::New < Views::Admin::Base
  prop :broadcast, PartnershipBroadcast, reader: :private
  prop :recipients, BroadcastRecipientsQuery, reader: :private

  def view_template
    content_for(:title) { t('admin.partnership_broadcasts.new.title', partnership: broadcast.partnership.name) }

    PageHeader(model_name: Partnership.model_name.human,
               title: t('admin.partnership_broadcasts.new.title', partnership: broadcast.partnership.name),
               id: broadcast.partnership.id)

    Error(broadcast)
    render_recipient_preview
    render_form
  end

  private

  def render_recipient_preview
    div(class: 'alert alert-info mb-6') do
      div do
        p(class: 'font-semibold') do
          t('admin.partnership_broadcasts.preview.reach',
            people: recipients.eligible.size,
            partners: recipients.partners_count)
        end
        if recipients.excluded_count.positive?
          p(class: 'text-sm') do
            t('admin.partnership_broadcasts.preview.excluded', count: recipients.excluded_count)
          end
        end
      end
    end
  end

  def render_form
    simple_form_for(broadcast,
                    url: admin_partnership_broadcasts_path(broadcast.partnership),
                    method: :post,
                    html: { class: 'space-y-6 max-w-2xl' }) do |form|
      div(class: 'fieldset') do
        label(for: 'partnership_broadcast_subject', class: 'fieldset-legend') do
          attr_label(:partnership_broadcast, :subject)
        end
        raw form.input_field(:subject, class: 'input input-bordered w-full',
                                       id: 'partnership_broadcast_subject')
      end

      div(class: 'fieldset') do
        label(for: 'partnership_broadcast_body', class: 'fieldset-legend') do
          attr_label(:partnership_broadcast, :body)
        end
        raw form.input_field(:body, as: :text, rows: 12,
                                    class: 'textarea textarea-bordered w-full',
                                    id: 'partnership_broadcast_body')
        p(class: 'fieldset-label') { t('admin.partnership_broadcasts.new.body_hint') }
      end

      raw form.submit(t('admin.partnership_broadcasts.new.preview_button'),
                      class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange')
    end
  end
end
