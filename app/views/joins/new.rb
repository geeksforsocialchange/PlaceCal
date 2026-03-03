# frozen_string_literal: true

class Views::Joins::New < Views::Base
  register_output_helper :simple_form_for
  register_output_helper :invisible_captcha
  register_output_helper :icon

  prop :join, Join, reader: :private

  def view_template # rubocop:disable Metrics/AbcSize
    article(class: 'home') do
      div(class: 'margin') do
        div(class: 'card card--alt card--split center') do
          render_header
          div(class: 'card__body') do
            render_flash_messages
            render_form
          end
          p(class: 'regular-links') do
            plain 'Email us at '
            br(class: 'mobile-only')
            mail_to 'info@placecal.org'
          end
          br(class: 'half')
        end
      end
    end
  end

  private

  def render_header
    div(class: 'card__title') do
      h1(class: 'section') { 'Get in touch' }
      p(class: 'alt-title-small') { 'Want to run PlaceCal in your community, group, or area?' }
      p do
        plain 'Contact us to discuss how you can'
        br(class: 'tablet-up')
        plain ' join our not-for-profit social enterprise.'
      end
    end
  end

  def render_flash_messages
    return unless view_context.flash.any?

    div(class: 'flashes') do
      view_context.flash.each do |key, value|
        div(class: "alert alert-#{key}") { value }
      end
    end
  end

  def render_form # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    # rubocop:disable Rails/OutputSafety
    simple_form_for join, url: get_in_touch_path, html: { class: 'form' } do |f|
      invisible_captcha
      div(class: 'form__person form__mid-width') do
        div(class: 'form__field') { raw f.input(:name, label: 'Name:') }
        div(class: 'form__field') { raw f.input(:email, as: :email, label: 'Email address:') }
        div(class: 'form__field') { raw f.input(:job_title, label: 'Job title:') }
        div(class: 'form__field') { raw f.input(:phone, as: :tel, label: 'Phone number:') }
        div(class: 'form__field') { raw f.input(:job_org, label: 'Organisation name:') }
        div(class: 'form__field') { raw f.input(:area, label: 'The area it covers is:') }
      end

      div(class: 'form__contact form__small-width') do
        div(class: 'form__contact-child') do
          p { strong { "I'd like:" } }
        end
        div(class: 'form__contact-child') do
          render_checkbox(f, :ringback, 'A ring back')
          render_checkbox(f, :more_info, 'More information')
        end
      end

      div(class: 'form__info form__full-width') do
        raw f.input(:why, as: :text, label: 'Why I want PlaceCal:',
                          placeholder: "Enter information about why you'd like to join PlaceCal here")
      end

      raw f.submit('Submit', class: 'btn form__submit')
    end
    # rubocop:enable Rails/OutputSafety
  end

  def render_checkbox(form, field, label_text)
    div(class: 'form__checkbox') do
      raw form.check_box(field) # rubocop:disable Rails/OutputSafety
      label(for: "join_#{field}") do
        plain label_text
        icon(:form_checkbox, size: nil)
        icon(:form_checkbox_check, size: nil, css_class: 'checked')
      end
    end
  end
end
