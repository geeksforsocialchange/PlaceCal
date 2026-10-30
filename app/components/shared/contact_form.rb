# frozen_string_literal: true

# Named ContactForm because a ContactRequest component would shadow the model.
class Components::Shared::ContactForm < Components::Base
  register_output_helper :simple_form_for
  register_output_helper :invisible_captcha

  prop :contact_request, ContactRequest, reader: :private
  prop :url, String, reader: :private
  # Site pages show their own contact address instead of PlaceCal's.
  prop :email_cta, _Boolean, default: true

  def view_template
    render_form
    render_email_cta if @email_cta
  end

  private

  def render_form
    simple_form_for(contact_request, url:) do |f|
      invisible_captcha

      UI::Card(padding: :xl, class: 'join-card') do
        UI::Stack(gap: :lg) do
          div(class: 'join-grid grid grid-cols-1 md:grid-cols-2 gap-4') do
            render_field(f, :name, required: true)
            render_field(f, :email, type: 'email', required: true)
            render_field(f, :job_title)
            render_field(f, :phone, type: 'tel')
            render_field(f, :job_org)
            render_field(f, :area)
          end
          render_choices(f)
          render_field(f, :why, required: true, rows: 5, hook: 'join-block join-field')
          render_actions
        end
      end
    end
  end

  def render_field(form, attribute, type: 'text', required: false, rows: nil, hook: 'join-field')
    id = form.field_id(attribute)
    UI::Field(label: ContactRequest.human_attribute_name(attribute), id:, variant: :strong, required:, label_class: 'join-label', class: hook) do
      UI::Input(variant: :roomy, type:, rows:, id:, name: form.field_name(attribute), value: contact_request.public_send(attribute),
                required:, placeholder: t("contact_form.placeholders.#{attribute}"), class: 'join-control')
    end
  end

  def render_choices(form)
    UI::Fieldset(legend: t('contact_form.choices_legend'), legend_class: 'join-label', class: 'join-block') do
      UI::Cluster(gap: :sm, class: 'join-choices') do
        %i[ringback more_info].each do |attribute|
          UI::Choice(label: ContactRequest.human_attribute_name(attribute), box_class: 'join-choice__box', class: 'join-choice') do
            raw form.check_box(attribute)
          end
        end
      end
    end
  end

  def render_actions
    UI::Cluster(gap: :md, class: 'join-actions') do
      UI::Button(variant: :dark_invert, size: :xl, type: 'submit', class: 'join-submit') { t('contact_form.submit') }
      p(class: 'join-note max-w-(--width-note) text-sm leading-normal text-tertiary') { t('contact_form.note') }
    end
  end

  def render_email_cta
    Shared::EmailCta(heading: t('contact_form.email_cta.heading'), body: t('contact_form.email_cta.body'), address: t('contact.email'))
  end
end
