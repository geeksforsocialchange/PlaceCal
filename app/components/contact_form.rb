# frozen_string_literal: true

# The ContactRequest enquiry form (card, choice chips, email fallback CTA),
# shared by the directory's get-in-touch page and the join site's book-a-demo
# page — the two pages post the same model to their own URL. Copy lives under
# contact_form.* in en.yml; the join-* classes are in
# app/tailwind/public/_components.css.
#
# Named ContactForm, not ContactRequest: a component constant matching the
# model name would shadow the model through the components kit.
class Components::ContactForm < Components::Base
  register_output_helper :simple_form_for
  register_output_helper :invisible_captcha
  register_output_helper :icon

  prop :contact_request, ContactRequest, reader: :private
  prop :url, String, reader: :private

  def view_template
    render_form
    render_email_cta
  end

  private

  # simple_form_for gives us the form tag, CSRF token and model binding. We
  # render each control with the plain Rails form-builder helpers (text_field,
  # check_box, submit, …) rather than simple_form's `f.input` wrappers so the
  # bespoke label/grid/chip markup below is fully under our control. Those
  # helpers return an ActiveSupport::SafeBuffer, which `raw` writes straight
  # into the Phlex output buffer.
  def render_form
    simple_form_for contact_request, url: url do |f|
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
        placeholder: t("contact_form.placeholders.#{attribute}")
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
        placeholder: t('contact_form.placeholders.why')
      )
    end
  end

  def render_choices(form)
    div(class: 'join-block') do
      p(class: 'join-label mb-3') { t('contact_form.choices_legend') }
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
      plain ContactRequest.human_attribute_name(attribute)
    end
  end

  def render_actions(form)
    div(class: 'join-actions') do
      raw form.submit(t('contact_form.submit'), class: 'join-submit')
      p(class: 'join-note') { t('contact_form.note') }
    end
  end

  # Field label with a required (*) or optional marker, matching the design.
  def render_label(attribute, required: false)
    label(for: "contact_request_#{attribute}", class: 'join-label') do
      plain ContactRequest.human_attribute_name(attribute)
      if required
        span(class: 'req', aria_hidden: 'true') { '*' }
      else
        span(class: 'opt') { t('contact_form.optional') }
      end
    end
  end

  def render_email_cta
    address = t('contact_form.email_cta.address')

    div(class: 'join-email-cta') do
      div do
        # h2 (not h3) to keep the heading order correct after the page's h1.
        h2(class: 'join-email-cta__heading') { t('contact_form.email_cta.heading') }
        p(class: 'join-email-cta__body') { t('contact_form.email_cta.body') }
      end
      a(href: "mailto:#{address}", class: 'join-email-link with-no-sass') do
        icon(:mail, size: '4')
        plain address
      end
    end
  end
end
