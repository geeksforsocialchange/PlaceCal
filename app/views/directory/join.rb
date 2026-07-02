# frozen_string_literal: true

class Views::Directory::Join < Views::Base
  register_output_helper :simple_form_for
  register_output_helper :invisible_captcha
  register_output_helper :icon

  prop :join_request, JoinRequest, reader: :private

  def view_template
    content_for(:title) { t('directory.join.hero.title') }

    Directory::PageHero(
      title: t('directory.join.hero.title'),
      kicker: t('directory.join.hero.kicker'),
      subtitle: t('directory.join.hero.subtitle'),
      breadcrumb_label: t('directory.join.hero.breadcrumb')
    )

    div(class: 'container-editorial py-8') do
      render_form
      render_email_cta
    end
  end

  private

  # simple_form_for gives us the form tag, CSRF token and model binding. We
  # render each control with the plain Rails form-builder helpers (text_field,
  # check_box, submit, …) rather than simple_form's `f.input` wrappers so the
  # bespoke label/grid/chip markup below is fully under our control. Those
  # helpers return an ActiveSupport::SafeBuffer, which `raw` writes straight
  # into the Phlex output buffer.
  def render_form
    simple_form_for join_request, url: get_in_touch_path do |f|
      invisible_captcha

      div(class: 'join-card') do
        div(class: 'join-grid') do
          render_field(f, :name, required: true)
          render_field(f, :email, type: :email_field, required: true)
          render_field(f, :job_title)
          render_field(f, :phone, type: :telephone_field)
          render_field(f, :job_org)
          render_field(f, :area)
        end

        render_choices(f)
        render_why(f)
        render_actions(f)
      end
    end
  end

  # A single labelled text input in the field grid.
  def render_field(form, attribute, type: :text_field, required: false)
    div(class: 'join-field') do
      render_label(attribute, required:)
      raw form.public_send(
        type, attribute,
        class: 'join-control',
        required:,
        placeholder: t("directory.join.placeholders.#{attribute}")
      )
    end
  end

  def render_why(form)
    div(class: 'join-block join-field') do
      render_label(:why, required: true)
      raw form.text_area(
        :why,
        class: 'join-control',
        rows: 5,
        required: true,
        placeholder: t('directory.join.placeholders.why')
      )
    end
  end

  def render_choices(form)
    div(class: 'join-block') do
      p(class: 'join-label mb-3') { t('directory.join.choices_legend') }
      div(class: 'join-choices') do
        render_choice(form, :ringback)
        render_choice(form, :more_info)
      end
    end
  end

  def render_choice(form, attribute)
    label(class: 'join-choice') do
      raw form.check_box(attribute)
      span(class: 'join-choice__box') { icon(:check, size: '4') }
      plain JoinRequest.human_attribute_name(attribute)
    end
  end

  def render_actions(form)
    div(class: 'join-actions') do
      raw form.submit(t('directory.join.submit'), class: 'join-submit')
      p(class: 'join-note') { t('directory.join.note') }
    end
  end

  # Field label with a required (*) or optional marker, matching the design.
  def render_label(attribute, required: false)
    label(for: "join_request_#{attribute}", class: 'join-label') do
      plain JoinRequest.human_attribute_name(attribute)
      if required
        span(class: 'req', aria_hidden: 'true') { '*' }
      else
        span(class: 'opt') { t('directory.join.optional') }
      end
    end
  end

  def render_email_cta
    address = t('directory.join.email_cta.address')

    div(class: 'join-email-cta') do
      div do
        # h2 (not h3) to keep the heading order correct after the hero's h1.
        h2(class: 'join-email-cta__heading') { t('directory.join.email_cta.heading') }
        p(class: 'join-email-cta__body') { t('directory.join.email_cta.body') }
      end
      a(href: "mailto:#{address}", class: 'join-email-link with-no-sass') do
        icon(:mail, size: '4')
        plain address
      end
    end
  end
end
