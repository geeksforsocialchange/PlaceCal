# frozen_string_literal: true

class Views::Admin::PartnershipBroadcasts::Index < Views::Admin::Base
  prop :partnership, Partnership, reader: :private
  prop :broadcasts, ActiveRecord::Relation, reader: :private

  def view_template
    content_for(:title) { t('admin.partnership_broadcasts.index.title', partnership: partnership.name) }

    div(class: 'flex items-center justify-between mb-6') do
      div do
        h1(class: 'text-2xl font-semibold') { t('admin.partnership_broadcasts.index.title', partnership: partnership.name) }
        p(class: 'text-gray-600 mt-1') { t('admin.partnership_broadcasts.index.subtitle') }
      end
      a(href: new_admin_partnership_broadcast_path(partnership),
        class: 'btn bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange') do
        t('admin.partnership_broadcasts.index.new_button')
      end
    end

    if broadcasts.empty?
      p(class: 'text-gray-500') { t('admin.partnership_broadcasts.index.empty') }
    else
      render_table
    end
  end

  private

  def render_table
    div(class: 'overflow-x-auto') do
      table(class: 'table') do
        thead do
          tr do
            th { t('admin.partnership_broadcasts.index.columns.sent_at') }
            th { t('admin.partnership_broadcasts.index.columns.subject') }
            th { t('admin.partnership_broadcasts.index.columns.sender') }
            th(class: 'text-right') { t('admin.partnership_broadcasts.index.columns.recipients') }
            th(class: 'text-right') { t('admin.partnership_broadcasts.index.columns.excluded') }
          end
        end
        tbody do
          broadcasts.each do |broadcast|
            tr do
              td { l(broadcast.created_at, format: :datetime) }
              td(class: 'font-medium') { broadcast.subject }
              td { broadcast.sender&.admin_name || t('admin.partnership_broadcasts.index.deleted_sender') }
              td(class: 'text-right') { broadcast.recipient_count.to_s }
              td(class: 'text-right') { broadcast.excluded_count.to_s }
            end
          end
        end
      end
    end
  end

  def l(value, **)
    I18n.l(value, **)
  end
end
