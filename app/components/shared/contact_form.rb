# frozen_string_literal: true

# Named ContactForm because a ContactRequest component would shadow the model.
class Components::Shared::ContactForm < Components::Base
  register_output_helper :simple_form_for
  register_output_helper :invisible_captcha

  theme_scope :contact_form,
              parts: {
                card: 'The card holding the form.',
                grid: 'The two-column grid of short fields.',
                field: 'One field: its label, then its control. The why field spans the grid (see the variant).',
                label: 'A field\'s label, or the choices\' legend.',
                control: 'A field\'s input or textarea.',
                choice_group: 'The fieldset holding the tick-box choices.',
                choices: 'The row of choices.',
                choice: 'One choice: its tick box and label.',
                choice_box: 'The tick box inside a choice.',
                actions: 'The row holding the submit button and the note.',
                note: 'The note beside the submit button.'
              },
              variants: { field: %i[wide] },
              tokens: %i[--color-background --color-foreground --color-surface --color-tertiary --color-rules --color-rules-dark --color-focus-ring
                         --color-secondary-strong --color-home-background --color-home-background-3 --font-weight-regular --font-weight-semibold
                         --font-weight-bold --font-weight-extra-bold --text-sm --text-detail --text-base --leading-normal --radius-card --radius-field
                         --radius-check --radius-pill]

  prop :contact_request, ContactRequest, reader: :private
  prop :url, String, reader: :private
  # Site pages show their own contact address instead of PlaceCal's.
  prop :email_cta, _Boolean, default: true

  def view_template
    UI::Stack(gap: :md) do
      render_form
      render_email_cta if @email_cta
    end
  end

  private

  def render_form
    simple_form_for(contact_request, url:) do |f|
      invisible_captcha

      UI::Card(padding: :xl, **part(:card)) do
        UI::Stack(gap: :lg) do
          div(**part(:grid, class: 'grid grid-cols-1 md:grid-cols-2 gap-4')) do
            render_field(f, :name, required: true)
            render_field(f, :email, type: 'email', required: true)
            render_field(f, :job_title)
            render_field(f, :phone, type: 'tel')
            render_field(f, :job_org)
            render_field(f, :area)
          end
          render_choices(f)
          render_field(f, :why, required: true, rows: 5, wide: true)
          render_actions
        end
      end
    end
  end

  def render_field(form, attribute, type: 'text', required: false, rows: nil, wide: false)
    id = form.field_id(attribute)
    UI::Field(label: ContactRequest.human_attribute_name(attribute), id:, variant: :strong, required:, label_attributes: part(:label),
              **part(:field, variant: (:wide if wide))) do
      UI::Input(variant: :roomy, type:, rows:, id:, name: form.field_name(attribute), value: contact_request.public_send(attribute),
                required:, placeholder: t("contact_form.placeholders.#{attribute}"), **part(:control))
    end
  end

  def render_choices(form)
    UI::Fieldset(legend: t('contact_form.choices_legend'), legend_attributes: part(:label), **part(:choice_group)) do
      UI::Cluster(gap: :sm, **part(:choices)) do
        %i[ringback more_info].each do |attribute|
          UI::Choice(label: ContactRequest.human_attribute_name(attribute), box_attributes: part(:choice_box), **part(:choice)) do
            raw form.check_box(attribute)
          end
        end
      end
    end
  end

  def render_actions
    UI::Cluster(gap: :md, **part(:actions)) do
      UI::Button(variant: :dark_invert, size: :xl, type: 'submit') { t('contact_form.submit') }
      p(**part(:note, class: 'max-w-(--width-note) text-sm leading-normal text-tertiary')) { t('contact_form.note') }
    end
  end

  def render_email_cta
    Shared::EmailCta(heading: t('contact_form.email_cta.heading'), body: t('contact_form.email_cta.body'), address: t('contact.email'))
  end
end
