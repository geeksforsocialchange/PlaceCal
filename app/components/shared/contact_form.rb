# frozen_string_literal: true

# Named ContactForm because a ContactRequest component would shadow the model.
class Components::Shared::ContactForm < Components::Base
  register_output_helper :simple_form_for
  register_output_helper :invisible_captcha
  register_output_helper :icon

  prop :contact_request, ContactRequest, reader: :private
  prop :url, String, reader: :private
  # Site pages show their own contact address instead of PlaceCal's.
  prop :email_cta, _Boolean, default: true

  def view_template
    render_form
    render_email_cta if @email_cta
  end

  private

  # Plain form-builder helpers, not f.input, so the label and chip markup stay ours.
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
    address = t('contact.email')

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
