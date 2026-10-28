# frozen_string_literal: true

class Components::Sites::HeroSection < Components::Base
  prop :image_path, _Nilable(String), default: nil
  prop :image_credit, _Nilable(String), default: nil
  prop :title, _Nilable(String), default: nil
  prop :alttext, _Nilable(String), default: nil

  def after_initialize
    @title = @title.presence || I18n.t('meta.description', site: 'PlaceCal')
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
    img(class: 'block w-full aspect-2/1 object-cover lg:aspect-3/1', src: @image_path, **attrs)
  end
end
