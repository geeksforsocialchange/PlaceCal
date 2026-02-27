# frozen_string_literal: true

class Components::HeroSection < Components::Base
  prop :image_path, _Nilable(String), default: nil
  prop :image_credit, _Nilable(String), default: nil
  prop :title, _Nilable(String), default: nil
  prop :alttext, _Nilable(String), default: nil

  def after_initialize
    @title = @title.presence || I18n.t('meta.description', site: 'PlaceCal')
  end

  def view_template
    div(class: 'hero_section') do
      if @image_path.presence
        img_attrs = { class: 'hero_section__img', src: @image_path }
        if @alttext.presence
          img_attrs[:alt] = @alttext
        else
          img_attrs[:'aria-hidden'] = 'true'
        end
        img(**img_attrs)
      end
      div(class: 'hero_section__text') do
        p(class: 'hero_section__credit') { "Image credit: #{@image_credit}" } if @image_credit.presence
        h1(class: 'hero_section__title') { @title }
      end
    end
  end
end
