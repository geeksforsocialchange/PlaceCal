# frozen_string_literal: true

# "Book a demo" enquiry form. Reuses the join-* form treatment shared with the
# directory's get-in-touch page (app/tailwind/public/_components.css).
class Views::Join::Demo < Views::Join::Base
  register_output_helper :simple_form_for
  register_output_helper :invisible_captcha

  prop :demo_request, ::DemoRequest, reader: :private

  def view_template
    content_for(:title) { t('join.demo.title') }

    section(class: 'py-10') do
      div(class: 'container-editorial') do
        div(class: 'text-center mb-8') do
          h1(class: 'join-headline m-0 mb-2') { t('join.demo.title') }
          p(class: 'text-base text-tertiary leading-relaxed max-w-(--width-prose-md) mx-auto m-0') { t('join.demo.lede') }
        end
        div(class: 'max-w-[520px] mx-auto') { render_form }
      end
    end
  end

  private

  # Rendered with the plain form-builder helpers (see Views::Directory::Join
  # for the pattern) so the label/field markup stays under our control.
  def render_form
    simple_form_for demo_request, url: join_demo_path do |f|
      invisible_captcha

      div(class: 'join-card') do
        div(class: 'flex flex-col gap-4') do
          render_field(f, :name, required: true)
          render_field(f, :email, type: :email_field, required: true)
          render_field(f, :organisation)
          render_audience(f)
          render_message(f)
        end
        render_actions(f)
      end
    end
  end

  def render_field(form, attribute, type: :text_field, required: false)
    div(class: 'join-field') do
      render_label(attribute, required:)
      raw form.public_send(
        type, attribute,
        class: 'join-control',
        required:,
        placeholder: t("join.demo.placeholders.#{attribute}")
      )
    end
  end

  def render_audience(form)
    div(class: 'join-field') do
      render_label(:audience)
      raw form.select(
        :audience,
        ::DemoRequest::AUDIENCES.map { |key| [t("join.audiences.#{key}.title"), key] },
        { include_blank: t('join.demo.select_prompt') },
        class: 'join-control select-arrow appearance-none'
      )
    end
  end

  def render_message(form)
    div(class: 'join-field') do
      render_label(:message)
      raw form.text_area(
        :message,
        class: 'join-control',
        rows: 4,
        placeholder: t('join.demo.placeholders.message')
      )
    end
  end

  def render_actions(form)
    div(class: 'join-actions') do
      raw form.submit(t('join.demo.submit'), class: 'btn-join')
      p(class: 'join-note') { t('join.demo.note') }
    end
  end

  def render_label(attribute, required: false)
    label(for: "demo_request_#{attribute}", class: 'join-label') do
      plain ::DemoRequest.human_attribute_name(attribute)
      if required
        span(class: 'req', aria_hidden: 'true') { '*' }
      else
        span(class: 'opt') { t('join.demo.optional') }
      end
    end
  end
end
