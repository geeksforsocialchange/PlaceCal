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

  def render_form
    simple_form_for(contact_request, url:) do |f|
      invisible_captcha

      div(class: 'join-card bg-background border-2 border-rules rounded-card pt-8 px-9 pb-9') do
        div(class: 'join-grid grid grid-cols-1 md:grid-cols-2 gap-y-4.5 gap-x-5') do
          render_field(f, :name, required: true)
          render_field(f, :email, type: 'email', required: true)
          render_field(f, :job_title)
          render_field(f, :phone, type: 'tel')
          render_field(f, :job_org)
          render_field(f, :area)
        end

        render_choices(f)
        div(class: 'join-block mt-5.5') { render_field(f, :why, required: true, rows: 5) }
        render_actions
      end
    end
  end

  def render_field(form, attribute, type: 'text', required: false, rows: nil)
    id = form.field_id(attribute)
    UI::Field(label: ContactRequest.human_attribute_name(attribute), id:, variant: :strong, required:,
              label_class: 'join-label', class: 'join-field') do
      UI::Input(variant: :roomy, type:, rows:, id:, name: form.field_name(attribute), value: contact_request.public_send(attribute),
                required:, placeholder: t("contact_form.placeholders.#{attribute}"), class: 'join-control')
    end
  end

  def render_choices(form)
    div(class: 'join-block mt-5.5') do
      p(class: "join-label #{UI::Field::VARIANTS[:strong][:label]} mb-3") { t('contact_form.choices_legend') }
      div(class: 'join-choices flex flex-wrap gap-2.75') do
        render_choice(form, :ringback)
        render_choice(form, :more_info)
      end
    end
  end

  def render_choice(form, attribute)
    label(class: 'join-choice group relative inline-flex items-center gap-2.5 py-2.5 pr-4.5 pl-3.25 border-2 border-rules-dark rounded-pill ' \
                 'bg-background cursor-pointer font-bold text-detail text-foreground select-none transition-colors hover:border-tertiary ' \
                 'has-checked:border-foreground has-checked:bg-home-background-3 has-focus-visible:ring-3 has-focus-visible:ring-focus-ring') do
      raw form.check_box(attribute, class: 'absolute opacity-0 pointer-events-none')
      span(class: 'join-choice__box grid place-items-center size-5 shrink-0 border-2 border-rules-dark rounded-check bg-surface transition-colors ' \
                  'group-has-checked:bg-foreground group-has-checked:border-foreground') do
        icon(:check, size: '4', css_class: 'text-background opacity-0 scale-60 transition group-has-checked:opacity-100 group-has-checked:scale-100')
      end
      plain ContactRequest.human_attribute_name(attribute)
    end
  end

  def render_actions
    div(class: 'join-actions flex flex-wrap items-center gap-5 mt-7.5') do
      UI::Button(variant: :dark_invert, size: :xl, type: 'submit', class: 'join-submit') { t('contact_form.submit') }
      p(class: 'join-note max-w-(--width-note) text-sm leading-normal text-tertiary') { t('contact_form.note') }
    end
  end

  def render_email_cta
    Shared::EmailCta(heading: t('contact_form.email_cta.heading'), body: t('contact_form.email_cta.body'), address: t('contact.email'))
  end
end
