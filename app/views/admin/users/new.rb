# frozen_string_literal: true

class Views::Admin::Users::New < Views::Admin::Base
  prop :user, User, reader: :private

  def view_template
    content_for(:title) { 'New User' }

    display_fields = helpers.policy(helpers.current_user).permitted_attributes_for_create

    div(data: { controller: 'user-wizard',
                'user-wizard-current-step-value': '1',
                'user-wizard-total-steps-value': '2' }) do
      div(class: 'max-w-4xl mx-auto') do
        render_header
        render_steps_indicator
      end

      filtered_form_for([:admin, user],
                        display_only: display_fields,
                        html: { class: 'space-y-6', data: { controller: 'live-validation', user_wizard_target: 'form' } }) do |form|
        Error(user)

        div(class: 'max-w-4xl mx-auto') do
          render_step_personal(form)
          render_step_permissions(form)
        end

        SaveBar(
          wizard: true,
          wizard_controller: 'user-wizard',
          submit_label: t('admin.users.actions.invite'),
          submit_icon: :mail
        )
      end
    end
  end

  private

  def render_header
    div(class: 'text-center mb-8') do
      h1(class: 'text-2xl font-bold text-base-content mb-2') { 'Invite a New User' }
      p(class: 'text-gray-600') { 'Add a new user to PlaceCal and set their permissions' }
    end
  end

  def render_steps_indicator
    ul(class: 'steps steps-horizontal w-full mb-8') do
      li(class: 'step step-primary', data: { 'user-wizard-target': 'stepIndicator', step: '1' }) do
        span(class: 'step-content') { 'Personal Details' }
      end
      li(class: 'step', data: { 'user-wizard-target': 'stepIndicator', step: '2' }) do
        span(class: 'step-content') { 'Permissions' }
      end
    end
  end

  def render_step_personal(form)
    div(data: { 'user-wizard-target': 'step', step: '1' }) do
      render_personal_details_card(form)
      render_role_card(form) if helpers.current_user.root?
    end
  end

  def render_personal_details_card(form)
    div(class: 'card bg-base-100 shadow-lg border border-base-300') do
      div(class: 'card-body') do
        render_step_header(:user, 'Personal Details',
                           'Enter the basic information for this user. An invitation will be sent to their email.')
        div(class: 'grid grid-cols-1 md:grid-cols-2 gap-4') do
          render_text_field(form, :first_name, attr_label(:user, :first_name))
          render_text_field(form, :last_name, attr_label(:user, :last_name))
        end
        render_email_field(form)
        render_text_field(form, :phone, attr_label(:user, :phone))
      end
    end
  end

  def render_text_field(form, field, label_text)
    fieldset(class: 'fieldset bg-base-200/50 rounded-xl p-4') do
      raw form.label(field, label_text, class: 'fieldset-legend font-semibold')
      raw form.input_field(field, class: 'input input-bordered w-full')
    end
  end

  def render_email_field(form)
    fieldset(class: 'fieldset bg-base-200/50 rounded-xl p-4') do
      raw form.label(:email, class: 'fieldset-legend font-semibold') {
        "#{attr_label(:user, :email)} <span class=\"text-error\">#{t('admin.labels.required')}</span>".html_safe
      }
      raw form.input_field(:email,
                           class: 'input input-bordered w-full',
                           autocomplete: 'off',
                           data: { user_wizard_target: 'emailInput', action: 'input->user-wizard#checkEmail' })
      p(class: 'text-sm text-gray-600 mt-2') { 'An invitation email will be sent to this address.' }
      div(class: 'mt-3 hidden', data: { 'user-wizard-target': 'emailFeedback' }) do
        div(class: 'alert alert-success text-sm hidden', data: { 'user-wizard-target': 'emailAvailable' }) do
          raw icon(:check_circle, size: '5', css_class: 'shrink-0')
          span { 'This email address is available.' }
        end
        div(class: 'alert alert-warning text-sm hidden', data: { 'user-wizard-target': 'emailTaken' }) do
          raw icon(:warning, size: '5', css_class: 'shrink-0')
          div(class: 'flex-1') do
            p(class: 'font-semibold') { 'A user with this email already exists' }
            p(class: 'text-xs mt-1') { 'You may want to edit the existing user instead.' }
          end
          a(href: '#', class: 'btn btn-sm btn-warning', data: { 'user-wizard-target': 'emailTakenLink' }) { 'View User' }
        end
        div(class: 'alert alert-error text-sm hidden', data: { 'user-wizard-target': 'emailInvalid' }) do
          raw icon(:x_circle, size: '5', css_class: 'shrink-0')
          span { 'Please enter a valid email address.' }
        end
      end
    end
  end

  def render_role_card(form)
    div(class: 'card bg-base-100 shadow-lg border border-base-300 mt-6') do
      div(class: 'card-body') do
        render_step_header(:crown, attr_label(:user, :role), t('admin.users.fields.role_hint'))
        RadioCardGroup(
          form: form, attribute: :role,
          values: User.role.values, i18n_scope: 'admin.users.roles'
        )
      end
    end
  end

  def render_step_permissions(form)
    div(class: 'hidden', data: { 'user-wizard-target': 'step', step: '2' }) do
      div(class: 'grid grid-cols-1 lg:grid-cols-2 gap-6') do
        render_partners_card(form)
        render_partnerships_card(form)
        render_neighbourhoods_card(form)
      end
      div(role: 'alert', class: 'alert bg-blue-50 border-blue-200 text-blue-800 mt-6') do
        raw icon(:info, size: '5', css_class: 'text-blue-500')
        span do
          plain 'Inviting a user will require their acceptance of the PlaceCal '
          a(href: helpers.terms_of_use_path, class: 'link link-hover text-placecal-teal font-medium') { 'Terms of Use' }
          plain '.'
        end
      end
    end
  end

  def render_partners_card(_form)
    div(class: 'card bg-base-100 shadow-lg border border-base-300') do
      div(class: 'card-body') do
        render_permission_header(:partner, 'from-emerald-100 to-teal-100', 'text-emerald-600',
                                 Partner.model_name.human(count: 2), t('admin.users.fields.partners_hint'))
        StackedListSelector(
          field_name: 'user[partner_ids][]',
          items: user.partners.order(:name),
          options: options_for_partners(user),
          permitted_ids: permitted_options_for_partners,
          icon_name: :partner, icon_color: 'bg-emerald-100 text-emerald-600',
          empty_text: t('admin.empty.none_assigned', items: Partner.model_name.human(count: 2).downcase),
          add_placeholder: t('admin.placeholders.add_model', model: Partner.model_name.human.downcase),
          use_tom_select: true, wrapper_class: 'user_partners'
        )
      end
    end
  end

  def render_partnerships_card(_form)
    div(class: 'card bg-base-100 shadow-lg border border-base-300') do
      div(class: 'card-body') do
        render_permission_header(:partnership, 'from-amber-100 to-orange-100', 'text-amber-700',
                                 Partnership.model_name.human(count: 2), t('admin.users.fields.partnerships_hint'))
        StackedListSelector(
          field_name: 'user[tag_ids][]',
          items: user.partnerships.order(:name),
          options: options_for_user_partnerships,
          permitted_ids: nil,
          icon_name: :partnership, icon_color: 'bg-amber-100 text-amber-700',
          empty_text: t('admin.empty.none_assigned', items: Partnership.model_name.human(count: 2).downcase),
          add_placeholder: t('admin.placeholders.add_model', model: Partnership.model_name.human.downcase),
          wrapper_class: 'user_partnerships'
        )
      end
    end
  end

  def render_neighbourhoods_card(form)
    div(class: 'card bg-base-100 shadow-lg border border-base-300 lg:col-span-2') do
      div(class: 'card-body') do
        neighbourhoods_hint = helpers.current_user.root? ? t('admin.users.fields.neighbourhoods_hint_root') : t('admin.users.fields.neighbourhoods_hint')
        render_permission_header(:map_pin, 'from-sky-100 to-blue-100', 'text-sky-600',
                                 Neighbourhood.model_name.human(count: 2), neighbourhoods_hint)
        if helpers.current_user.root?
          nested_form_for(form, :neighbourhoods_users,
                          add_text: t('admin.actions.add_model', model: Neighbourhood.model_name.human.downcase),
                          add_class: 'btn btn-sm bg-placecal-orange hover:bg-orange-600 text-white border-placecal-orange mt-2',
                          partial: 'neighbourhoods_user_fields') do
            raw form.simple_fields_for(:neighbourhoods_users) { |nuf| view_context.render('neighbourhoods_user_fields', f: nuf) }
          end
        else
          ItemBadgeList(
            items: user.neighbourhoods.order(:name),
            icon_name: :map_pin, icon_color: 'bg-sky-100 text-sky-600',
            link_path: :admin_neighbourhood_path,
            empty_text: t('admin.empty.none_assigned', items: Neighbourhood.model_name.human(count: 2).downcase)
          )
        end
      end
    end
  end

  def render_step_header(icon_name, title, description)
    div(class: 'flex items-start gap-4 mb-6') do
      div(class: 'shrink-0 w-12 h-12 rounded-xl bg-placecal-orange/10 flex items-center justify-center') do
        raw icon(icon_name, size: '6', css_class: 'text-placecal-orange')
      end
      div do
        h2(class: 'card-title text-xl') { title }
        p(class: 'text-gray-600 text-sm mt-1') { description }
      end
    end
  end

  def render_permission_header(icon_name, gradient, text_color, title, description)
    div(class: 'flex items-start gap-4 mb-4') do
      div(class: "shrink-0 w-11 h-11 rounded-xl bg-linear-to-br #{gradient} flex items-center justify-center shadow-sm") do
        raw icon(icon_name, size: '6', css_class: text_color)
      end
      div do
        h2(class: 'card-title text-lg') { title }
        p(class: 'text-sm text-gray-600 mt-0.5') { description }
      end
    end
  end
end
