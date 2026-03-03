# frozen_string_literal: true

class Views::Admin::Users::FormTabSettings < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template
    user = form.object

    div(class: 'space-y-8') do
      render_role_card

      render_danger_zone(user)
    end
  end

  private

  def render_role_card
    div(class: 'max-w-2xl') do
      FormCard(
        icon: :lock,
        title: attr_label(:user, :role),
        description: t('admin.users.fields.role_hint')
      ) do
        RadioCardGroup(
          form: form,
          attribute: :role,
          values: User.role.values,
          i18n_scope: 'admin.users.roles'
        )
      end
    end
  end

  def render_danger_zone(user)
    return unless user.persisted? && helpers.policy(user).destroy?

    div do
      h2(class: 'text-lg font-bold flex items-center gap-2 text-error/80 mb-4') do
        raw icon(:warning, size: '5')
        plain t('admin.sections.danger_zone')
      end

      div(class: 'max-w-2xl') do
        if user.site_admin?
          render_site_admin_warning
        else
          DangerZone(
            title: t('admin.danger_zone.delete_title', model: User.model_name.human),
            description: t('admin.danger_zone.delete_description', model: User.model_name.human.downcase),
            button_text: t('admin.actions.delete_model', model: User.model_name.human),
            button_path: helpers.admin_user_path(user),
            confirm: t('admin.confirm.delete_permanent', model: User.model_name.human.downcase)
          )
        end
      end
    end
  end

  def render_site_admin_warning
    div(class: 'card bg-base-200/50 border border-base-300') do
      div(class: 'card-body p-5') do
        h4(class: 'font-semibold flex items-center gap-2 mb-2 text-base-content/70') do
          raw icon(:trash, size: '5')
          plain t('admin.danger_zone.delete_title', model: User.model_name.human)
        end
        p(class: 'text-sm text-gray-600') { t('admin.users.danger_zone.site_admin_warning') }
      end
    end
  end
end
