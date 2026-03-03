# frozen_string_literal: true

class Views::Admin::Tags::FormTabSettings < Views::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    tag_record = form.object

    div(class: 'mb-8') do
      FormCard(
        icon: :link,
        title: attr_label(:tag, :slug),
        description: t('admin.hints.leave_blank_to_autogenerate')
      ) do
        label(for: 'tag_slug', class: 'sr-only') { attr_label(:tag, :slug) }
        raw form.input_field(:slug, class: 'input input-bordered w-full', disabled: tag_record.system_tag, id: 'tag_slug')
      end
    end

    render_advanced_section(tag_record)
    render_danger_zone(tag_record)
  end

  private

  def render_advanced_section(tag_record)
    return unless helpers.current_user.root? && !tag_record.is_a?(Partnership)

    div(class: 'mb-8') do
      FormCard(
        icon: :lock,
        title: t('admin.sections.advanced')
      ) do
        fieldset(class: 'fieldset') do
          raw form.input(:system_tag, wrapper: :tw_boolean, hint: t('admin.partnerships.fields.system_tag_hint'))
        end
      end
    end
  end

  def render_danger_zone(tag_record) # rubocop:disable Metrics/AbcSize
    return unless helpers.policy(tag_record).destroy?

    delete_path = if tag_record.is_a?(Partnership)
                    helpers.admin_partnership_path(tag_record)
                  else
                    helpers.admin_tag_path(tag_record)
                  end

    DangerZone(
      title: t('admin.actions.delete_model', model: tag_record.class.model_name.human),
      description: t('admin.danger_zone.delete_description', model: tag_record.class.model_name.human.downcase),
      button_text: t('admin.actions.delete_model', model: tag_record.class.model_name.human),
      button_path: delete_path,
      confirm: t('admin.confirm.delete_permanent', model: tag_record.class.model_name.human.downcase)
    )
  end
end
