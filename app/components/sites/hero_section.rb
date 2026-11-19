# frozen_string_literal: true

class Components::Sites::HeroSection < Components::Base
  # The hero fills the page, which stops widening at 1200px with the image 1128px across
  SIZES = '(min-width: 1200px) 1128px, 100vw'

  prop :image_path, _Nilable(String), default: nil
  prop :image_srcset, _Nilable(String), default: nil
  prop :image_webp_srcset, _Nilable(String), default: nil
  prop :image_credit, _Nilable(String), default: nil
  prop :title, _Nilable(String), default: nil
  prop :alttext, _Nilable(String), default: nil

  def after_initialize
    @title = @title.presence || I18n.t('components.hero_section.default_title')
  end

  def view_template
    div do
      render_image if @image_path.presence
      div(class: "relative flex flex-col items-center gap-6 p-6 rounded-t-card bg-background #{'-mt-4.5' if @image_path.presence}") do
        p(class: 'm-0 text-sm') { t('components.hero_section.image_credit', credit: @image_credit) } if @image_credit.presence
        h1(class: 'm-0 max-w-lg text-center text-2xl leading-tight lg:text-3xl') { @title }
      end
    end
  end

  private

  def render_image
    attrs = @alttext.presence ? { alt: @alttext } : { 'aria-hidden': 'true' }
    picture(class: 'block') do
      source(type: 'image/webp', srcset: @image_webp_srcset, sizes: SIZES) if @image_webp_srcset
      # The page's largest image, so it loads first; width and height reserve its space
      img(class: 'block w-full aspect-2/1 object-cover lg:aspect-3/1', src: @image_path, srcset: @image_srcset, sizes: (SIZES if @image_srcset),
          width: 2260, height: 700, fetchpriority: 'high', **attrs)
    end
  end
end
