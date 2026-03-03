# frozen_string_literal: true

class Views::Admin::Partners::FormTabSettings < Views::Admin::Base # rubocop:disable Metrics/ClassLength
  prop :form, ActionView::Helpers::FormBuilder, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    partner = form.object

    render_url_settings(partner)
    render_event_matching(partner)

    return if partner.new_record?

    render_moderation(partner)
    render_danger_zone(partner)
  end

  private

  def render_url_settings(partner) # rubocop:disable Metrics/MethodLength
    return unless helpers.policy(partner).permitted_attributes.include?(:slug)

    div(class: 'mb-8') do
      render Components::Admin::SectionHeader.new(
        title: t('admin.sections.url_settings'),
        description: t('admin.partners.sections.url_settings_description'),
        margin: 4
      )
      div(class: 'max-w-md') do
        fieldset(class: 'fieldset') do
          legend(class: 'fieldset-legend') do
            plain attr_label(:partner, :url)
            whitespace
            plain attr_label(:partner, :slug)
          end
          raw form.input_field(:slug, class: 'input input-bordered w-full')
          p(class: 'fieldset-label') { t('admin.hints.leave_blank_to_autogenerate') }
        end
      end
    end
  end

  def render_event_matching(partner) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    is_enabled = partner.can_be_assigned_events

    div(class: 'mb-8') do
      h2(class: 'text-lg font-bold mb-4') { t('admin.partners.sections.event_matching') }
      div(class: 'max-w-2xl') do
        div(class: 'card bg-base-200/50 border-2 border-base-300') do
          div(class: 'card-body p-5') do
            div(class: 'flex items-start gap-4') do
              render_event_matching_icon
              render_event_matching_content(is_enabled)
            end
          end
        end
      end

      render_event_matching_script
    end
  end

  def render_event_matching_icon
    div(class: 'shrink-0 w-12 h-12 rounded-xl bg-base-300 flex items-center justify-center') do
      raw icon(:swap, size: '6', css_class: 'text-gray-500')
    end
  end

  def render_event_matching_content(is_enabled) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'flex-1 min-w-0') do
      div(class: 'flex items-center justify-between gap-4 mb-2') do
        h3(class: 'font-semibold', id: 'event-matching-title') do
          plain is_enabled ? t('admin.partners.event_matching.enabled') : t('admin.partners.event_matching.disabled')
        end
        div(class: 'flex items-center gap-3') do
          span(class: 'label-text text-sm font-medium text-gray-600') { t('admin.labels.disabled') }
          raw form.check_box(:can_be_assigned_events,
                             class: 'toggle toggle-success',
                             id: 'partner_can_be_assigned_events',
                             onchange: 'updateEventMatchingTitle(this.checked)')
          span(class: 'label-text text-sm font-medium text-success') { t('admin.labels.enabled') }
        end
      end

      p(class: 'text-sm text-base-content/70 mb-3') { t('admin.partners.event_matching.description') }

      render_event_matching_benefits
    end
  end

  def render_event_matching_benefits # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'text-sm text-base-content/70 space-y-2') do
      p(class: 'font-medium text-base-content/90') { t('admin.partners.event_matching.when_enabled') }
      ul(class: 'list-none space-y-1.5 ml-0') do
        li(class: 'flex items-start gap-2') do
          raw icon(:check, size: '4', css_class: 'text-success shrink-0 mt-0.5')
          span { t('admin.partners.event_matching.benefit_1') }
        end
        li(class: 'flex items-start gap-2') do
          raw icon(:check, size: '4', css_class: 'text-success shrink-0 mt-0.5')
          span { t('admin.partners.event_matching.benefit_2') }
        end
        li(class: 'flex items-start gap-2') do
          raw icon(:info, size: '4', css_class: 'text-info shrink-0 mt-0.5')
          span { t('admin.partners.event_matching.benefit_3') }
        end
      end
    end
  end

  def render_event_matching_script
    script do
      raw safe(<<~JS)
        function updateEventMatchingTitle(isEnabled) {
          const title = document.getElementById('event-matching-title');
          title.textContent = isEnabled ? '#{t('admin.partners.event_matching.enabled')}' : '#{t('admin.partners.event_matching.disabled')}';
        }
      JS
    end
  end

  def render_moderation(partner) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    return unless helpers.policy(partner).permitted_attributes.include?(:hidden)

    div(class: 'mb-8') do
      h2(class: 'text-lg font-bold mb-4') { t('admin.partners.sections.moderation') }
      div(class: 'max-w-2xl', data: { controller: 'inverted-toggle' }) do
        div(class: 'card border-2 transition-colors', data: { inverted_toggle_target: 'card' }) do
          div(class: 'card-body p-5') do
            div(class: 'flex items-start gap-4') do
              render_moderation_icon
              render_moderation_content(partner)
            end
            render_moderation_reason_field
          end
        end
      end
    end

    render_visibility_script
  end

  def render_moderation_icon # rubocop:disable Metrics/MethodLength
    div(class: 'shrink-0 w-12 h-12 rounded-xl flex items-center justify-center transition-colors',
        data: { inverted_toggle_target: 'icon' }) do
      span(data: { inverted_toggle_target: 'iconHidden' }) do
        raw icon(:eye_off, size: '6', css_class: 'text-error')
      end
      span(data: { inverted_toggle_target: 'iconVisible' }) do
        raw icon(:eye, size: '6', css_class: 'text-warning')
      end
    end
  end

  def render_moderation_content(partner) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'flex-1 min-w-0') do
      div(class: 'flex items-center justify-between gap-4 mb-2') do
        h3(class: 'font-semibold transition-colors', data: { inverted_toggle_target: 'title' },
           id: 'partner-visibility-title') do
          plain partner.hidden? ? t('admin.partners.moderation.hidden_label') : t('admin.partners.moderation.visible_label')
        end
        div(class: 'flex items-center gap-3') do
          span(class: 'label-text text-sm font-medium text-error') { t('admin.labels.hidden') }
          raw form.hidden_field(:hidden,
                                value: partner.hidden? ? '1' : '0',
                                data: { inverted_toggle_target: 'hidden' })
          raw safe('<input type="checkbox" id="partner_hidden_toggle" class="toggle toggle-success" ' \
                   'data-inverted-toggle-target="checkbox" data-action="change->inverted-toggle#toggle" ' \
                   'onchange="updateVisibilityTitle(this.checked)" />')
          span(class: 'label-text text-sm font-medium text-success') { t('admin.labels.visible') }
        end
      end

      p(class: 'text-sm text-error/80 mb-3', data: { inverted_toggle_target: 'status' }) do
        plain t('admin.partners.moderation.hidden_status')
      end

      render_moderation_consequences
    end
  end

  def render_moderation_consequences # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    div(class: 'text-sm text-base-content/70 space-y-2') do
      p(class: 'font-medium text-base-content/90') { t('admin.partners.moderation.when_hidden') }
      ul(class: 'list-none space-y-1.5 ml-0') do
        li(class: 'flex items-start gap-2') do
          raw icon(:x, size: '4', css_class: 'text-warning shrink-0 mt-0.5')
          span { t('admin.partners.moderation.consequence_1') }
        end
        li(class: 'flex items-start gap-2') do
          raw icon(:x, size: '4', css_class: 'text-warning shrink-0 mt-0.5')
          span { t('admin.partners.moderation.consequence_2') }
        end
        li(class: 'flex items-start gap-2') do
          raw icon(:x, size: '4', css_class: 'text-warning shrink-0 mt-0.5')
          span { t('admin.partners.moderation.consequence_3') }
        end
        li(class: 'flex items-start gap-2') do
          raw icon(:check, size: '4', css_class: 'text-info shrink-0 mt-0.5')
          span { t('admin.partners.moderation.consequence_4') }
        end
        li(class: 'flex items-start gap-2') do
          raw icon(:bell, size: '4', css_class: 'text-info shrink-0 mt-0.5')
          span { t('admin.partners.moderation.consequence_5') }
        end
      end
    end
  end

  def render_moderation_reason_field # rubocop:disable Metrics/MethodLength
    div(class: 'mt-4 pt-4 border-t border-base-300/50') do
      fieldset(class: 'fieldset') do
        legend(class: 'fieldset-legend') { t('admin.partners.moderation.reason_label') }
        p(class: 'text-xs text-gray-600 mb-2') { t('admin.partners.moderation.reason_hint') }
        raw form.input_field(:hidden_reason,
                             class: 'textarea textarea-bordered w-full min-h-20 bg-base-100',
                             placeholder: t('admin.partners.moderation.reason_placeholder'),
                             data: { controller: 'auto-expand' })
      end
    end
  end

  def render_visibility_script
    script do
      raw safe(<<~JS)
        function updateVisibilityTitle(isVisible) {
          const title = document.getElementById('partner-visibility-title');
          title.textContent = isVisible ? '#{t('admin.partners.moderation.visible_label')}' : '#{t('admin.partners.moderation.hidden_label')}';
        }
      JS
    end
  end

  def render_danger_zone(partner) # rubocop:disable Metrics/MethodLength
    return unless helpers.policy(partner).destroy?

    div(class: 'mt-8') do
      render Components::Admin::DangerZone.new(
        title: t('admin.actions.delete_model', model: Partner.model_name.human.downcase),
        description: t('admin.danger_zone.delete_description', model: Partner.model_name.human.downcase),
        button_text: t('admin.actions.delete_model', model: Partner.model_name.human),
        button_path: helpers.admin_partner_path(partner),
        confirm: t('admin.confirm.delete_permanent', model: Partner.model_name.human.downcase)
      )
    end
  end
end
