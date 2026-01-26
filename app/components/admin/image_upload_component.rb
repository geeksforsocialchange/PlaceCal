# frozen_string_literal: true

module Admin
  class ImageUploadComponent < ViewComponent::Base
    include SvgIconsHelper

    # @param form [SimpleForm::FormBuilder] The form builder
    # @param attribute [Symbol] The attribute name for the image (e.g., :image, :avatar)
    # @param options [Hash] Optional configuration
    # @option options [String] :title The title to display above the upload area
    # @option options [Symbol] :header_icon The icon to show next to the title (default: :photo)
    # @option options [Symbol] :remove_attribute The attribute for the remove checkbox
    # @option options [String] :aspect CSS aspect ratio class (default: 'aspect-square')
    # @option options [String] :rounded CSS rounded class (default: 'rounded-lg')
    def initialize(form:, attribute:, **options)
      super()
      @form = form
      @attribute = attribute
      @title = options[:title]
      @header_icon = options[:header_icon] || :photo
      @remove_attribute = options[:remove_attribute] || :"remove_#{attribute}"
      @aspect = options[:aspect] || 'aspect-square'
      @rounded = options[:rounded] || 'rounded-lg'
    end

    attr_reader :form, :attribute, :title, :header_icon, :remove_attribute, :aspect, :rounded

    delegate :object, to: :form

    def uploader
      object.send(attribute)
    end

    def image_url
      # Handle different uploader configurations (some have .url directly, some have .retina.url)
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
      case attribute
      when :avatar then :user
      else :photo
      end
    end
  end
end
