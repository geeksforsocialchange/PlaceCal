# frozen_string_literal: true

class Components::Admin::ImageUpload < Components::Admin::Base
  prop :form, ActionView::Helpers::FormBuilder
  prop :attribute, Symbol
  prop :title, _Nilable(String), default: nil
  prop :header_icon, Symbol, default: :photo
  prop :remove_attribute, _Nilable(Symbol), default: nil
  prop :aspect, String, default: 'aspect-square'
  prop :rounded, String, default: 'rounded-lg'

  def after_initialize
    @remove_attribute = :"remove_#{@attribute}" if @remove_attribute.nil?
  end

  def view_template
    div(class: 'lg:border-l lg:border-base-300 lg:pl-6') do
      h2(class: 'font-semibold mb-4 flex items-center gap-2 text-base') do
        icon(@header_icon, size: '5', css_class: 'text-placecal-orange')
        plain(@title || object.class.human_attribute_name(@attribute))
      end
      div(data_controller: 'image-preview') do
        render_file_input
        render_image_preview
      end
    end
  end

  private

  def object
    @form.object
  end

  def uploader
    object.send(@attribute)
  end

  def image_url
    if uploader.respond_to?(:retina) && uploader.retina.url
      uploader.retina.url
    elsif uploader.respond_to?(:url) && uploader.url
      uploader.url
    end
  end

  def image?
    image_url.present?
  end

  def placeholder_icon
    case @attribute
    when :avatar then :user
    else :photo
    end
  end

  def render_file_input
    div(class: 'mb-4') do
      div(
        class: "relative overflow-hidden #{@rounded} border-2 border-dashed border-base-300 hover:border-placecal-orange transition-colors bg-base-200/50 hover:bg-base-200 cursor-pointer",
        data_image_preview_target: 'dropzone'
      ) do
        label(class: 'flex items-center gap-3 p-3 cursor-pointer') do
          div(class: 'flex-shrink-0 w-10 h-10 rounded-lg bg-placecal-orange/10 flex items-center justify-center') do
            icon(:upload, size: '5', css_class: 'text-placecal-orange')
          end
          div(class: 'flex-1 min-w-0') do
            p(class: 'text-sm font-medium text-base-content') { t('admin.images.choose_file_drag') }
            p(class: 'text-xs text-gray-600') { safe(image_uploader_hint(uploader)) }
          end
          safe(@form.input_field(@attribute, as: :file, class: 'sr-only',
                                             data: { action: 'change->image-preview#file', image_preview_target: 'input' }))
        end
      end
    end
  end

  def render_image_preview
    div(class: 'relative group', data_image_preview_target: 'wrapper') do
      if image?
        render_existing_image
      else
        render_placeholder
      end
    end
  end

  def render_existing_image
    div(class: "relative #{@rounded} overflow-hidden border border-base-300 bg-base-200") do
      image_tag image_url, class: "w-full h-auto #{@aspect} object-cover",
                           data: { image_preview_target: 'img' }
      div(class: 'absolute inset-0 bg-black/0 group-hover:bg-black/40 transition-colors flex items-center justify-center opacity-0 group-hover:opacity-100') do
        label(class: 'btn btn-sm bg-white/90 hover:bg-white text-base-content border-0 shadow-lg cursor-pointer') do
          icon(:upload, size: '4')
          plain " #{t('admin.images.replace')}"
          safe(@form.input_field(@attribute, as: :file, class: 'sr-only',
                                             data: { action: 'change->image-preview#file' }))
        end
      end
    end
    div(class: 'mt-2 flex justify-end') do
      label(class: 'inline-flex items-center gap-2 text-xs text-error cursor-pointer hover:text-red-700 transition-colors has-[:checked]:line-through has-[:checked]:opacity-60') do
        raw(safe(@form.check_box(@remove_attribute, class: 'sr-only')))
        icon(:trash, size: '3.5')
        plain " #{t('admin.images.remove_on_save')}"
      end
    end
  end

  def render_placeholder
    div(class: "#{@aspect} #{@rounded} border border-base-300 bg-base-200/50 flex items-center justify-center",
        data_image_preview_target: 'placeholder') do
      div(class: 'text-center text-gray-500 p-4') do
        icon(placeholder_icon, size: '16', css_class: 'mx-auto mb-3 opacity-50', stroke_width: '1')
        p(class: 'text-sm font-medium') { t('admin.images.no_image_uploaded') }
        p(class: 'text-xs mt-1') { t('admin.images.upload_hint') }
      end
    end
    image_tag '', style: 'display:none;',
                  class: "w-full h-auto #{@aspect} object-cover #{@rounded} border border-base-300",
                  data: { image_preview_target: 'img' }
  end
end
