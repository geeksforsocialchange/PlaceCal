# frozen_string_literal: true

class Views::Admin::Partners::FormTabAdmins < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    partner = form.object

    h2(class: 'text-lg font-bold mb-1 flex items-center gap-2') do
      raw icon(:user_add, size: '5')
      plain t('admin.models.admin.other')
      whitespace
      span(class: 'badge badge-sm badge-ghost') { partner.users.count.to_s }
    end
    p(class: 'text-sm text-gray-600 mb-6') { t('admin.partners.sections.admins_description') }

    StackedListSelector(
      field_name: 'partner[user_ids][]',
      items: partner.users,
      options: options_for_partner_users(partner),
      icon_name: :user,
      icon_color: 'bg-blue-100 text-blue-600',
      empty_text: t('admin.empty.none_assigned', items: t('admin.models.admin.other').downcase),
      add_placeholder: t('admin.partners.admins.add_existing'),
      use_tom_select: true,
      link_path: :edit_admin_user_path
    )

    return unless policy(User).create?

    div(class: 'mt-6') do
      link_to new_admin_user_path(partner_id: partner.id),
              class: 'btn btn-sm bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange' do
        raw icon(:plus, size: '4')
        plain t('admin.partners.admins.add_new')
      end
    end
  end
end
