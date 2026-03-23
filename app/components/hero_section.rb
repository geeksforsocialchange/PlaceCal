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
    div(class: 'grid grid-cols-1 grid-rows-[auto_1.11rem_auto]') do
      if @image_path.presence
        img_attrs = {
          class: 'aspect-[2/1] tl:aspect-[3/1] col-[1/2] row-[1/span_2] object-cover w-full',
          src: @image_path
        }
        if @alttext.presence
          img_attrs[:alt] = @alttext
        else
          img_attrs[:'aria-hidden'] = 'true'
        end
        img(**img_attrs)
      end
      div(class: 'flex flex-col items-center gap-[1.55rem] bg-base-background rounded-t-panel col-[1/2] row-[2/span_2] p-[1.55rem] z-10') do
        p(class: 'text-[0.8rem] m-0') { "Image credit: #{@image_credit}" } if @image_credit.presence
        h1(class: 'text-[1.77778rem] tl:text-[2.22222rem] leading-[1.2] m-0 max-w-content text-center') { @title }
      end
    end
  end
end
