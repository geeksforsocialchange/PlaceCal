# frozen_string_literal: true

class Views::Directory::Join < Views::Base
  register_output_helper :simple_form_for
  register_output_helper :invisible_captcha
  register_output_helper :icon

  prop :join, Join, reader: :private

  def view_template
    content_for(:title) { 'Get in touch' }

    Directory::PageHero(
      title: 'Get in touch',
      kicker: 'Join PlaceCal',
      subtitle: 'Want to run PlaceCal in your community, group, or area? Contact us to discuss how you can join our not-for-profit social enterprise.',
      breadcrumb_label: 'Get in touch'
    )

    div(class: 'container-public py-8') do
      div(class: 'max-w-(--width-prose-lg) mx-auto') do
        render_flash_messages
        render_form
        p(class: 'text-sm text-tertiary mt-6') do
          plain 'Email us at '
          mail_to 'info@placecal.org', class: 'text-foreground underline hover:decoration-primary'
        end
      end
    end
  end

  private

  def render_flash_messages
    return unless view_context.flash.any?

    div(class: 'mb-4') do
      view_context.flash.each do |_key, value|
        div(class: 'rounded-card px-4 py-3 text-sm font-bold bg-primary text-foreground') { value }
      end
    end
  end

  def render_form
    simple_form_for join, url: get_in_touch_path, html: { class: 'space-y-4' } do |f|
      invisible_captcha
      div(class: 'grid md:grid-cols-2 gap-4') do
        raw f.input(:name, label: 'Name', input_html: { class: input_class })
        raw f.input(:email, as: :email, label: 'Email address', input_html: { class: input_class })
        raw f.input(:job_title, label: 'Job title', input_html: { class: input_class })
        raw f.input(:phone, as: :tel, label: 'Phone number', input_html: { class: input_class })
        raw f.input(:job_org, label: 'Organisation name', input_html: { class: input_class })
        raw f.input(:area, label: 'The area it covers', input_html: { class: input_class })
      end

      div(class: 'bg-home-background-3 rounded-card p-4') do
        p(class: 'font-bold text-sm text-foreground mb-3') { "I'd like:" }
        div(class: 'flex flex-wrap gap-4') do
          render_checkbox(f, :ringback, 'A ring back')
          render_checkbox(f, :more_info, 'More information')
        end
      end

      raw f.input(:why, as: :text, label: 'Why I want PlaceCal',
                        placeholder: "Enter information about why you'd like to join PlaceCal here",
                        input_html: { class: "#{input_class} min-h-30", rows: 5 })

      raw f.submit('Submit',
                   class: 'bg-foreground text-background rounded-full px-6 py-3 text-sm font-bold border-0 cursor-pointer hover:bg-tertiary transition-colors')
    end
  end

  def render_checkbox(form, field, label_text)
    div(class: 'flex items-center gap-2') do
      raw form.check_box(field, class: 'w-4 h-4 accent-primary')
      label(for: "join_#{field}", class: 'text-sm text-foreground cursor-pointer') { label_text }
    end
  end

  def input_class
    'w-full border-2 border-rules rounded-card px-4 py-2 text-sm bg-background text-foreground outline-none focus:border-foreground transition-colors'
  end
end
