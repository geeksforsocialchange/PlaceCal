# frozen_string_literal: true

class Components::Directory::PageHero < Components::Directory::Base
  FADE = 'background: linear-gradient(to right, var(--color-foreground) 50%, ' \
         'color-mix(in srgb, var(--color-foreground) 75%, transparent) 62%, ' \
         'color-mix(in srgb, var(--color-foreground) 40%, transparent) 75%, ' \
         'color-mix(in srgb, var(--color-foreground) 15%, transparent) 88%, transparent 100%)'

  prop :title, String
  prop :kicker, _Nilable(String), default: nil
  prop :subtitle, _Nilable(String), default: nil
  prop :breadcrumb_label, _Nilable(String), default: nil
  prop :breadcrumb_path, _Nilable(String), default: nil
  # Multi-level trail rendered after the root crumb: [{ label:, path: }, ...].
  # Items without a path render as plain text. Takes precedence over the
  # single breadcrumb_label/breadcrumb_path pair.
  prop :breadcrumbs, _Nilable(Array), default: nil
  prop :background_image_url, _Nilable(String), default: nil
  prop :root_label, _Nilable(String), default: nil

  def view_template(&block)
    section(class: 'bg-foreground text-background pt-6 pb-4 relative overflow-hidden') do
      render_background_image if @background_image_url
      div(class: 'container-public relative z-10') do
        render_breadcrumb if @breadcrumb_label || @breadcrumbs
        render_kicker if @kicker
        h1(class: 'hero-title') { @title }
        render_subtitle if @subtitle
        yield if block
      end
    end
  end

  private

  def render_background_image
    div(
      class: 'absolute inset-0 bg-cover bg-center',
      style: "background-image: url('#{@background_image_url}')"
    )
    div(
      class: 'absolute inset-0',
      style: FADE
    )
  end

  def render_breadcrumb
    nav(class: 'text-sm mb-2 text-background', aria_label: t('directory.aria.breadcrumb')) do
      root_label = @root_label || t('directory.breadcrumbs.root')
      UI::Link(href: root_path, variant: :quiet, tone: :inherit) { root_label }
      crumb_items.each do |item|
        span(class: 'mx-1.5 opacity-60') { safe('›') }
        if item[:path]
          span(class: 'opacity-80') { UI::Link(href: item[:path], variant: :quiet, tone: :inherit) { item[:label] } }
        else
          span(class: 'opacity-80') { item[:label] }
        end
      end
    end
  end

  def crumb_items
    @breadcrumbs || [{ label: @breadcrumb_label, path: @breadcrumb_path }]
  end

  def render_kicker
    UI::Kicker(tone: :faded, spacing: :xs) { @kicker }
  end

  def render_subtitle
    div(class: ['text-base leading-relaxed max-w-(--width-prose-md) mb-2',
                @background_image_url ? 'bg-foreground/80 rounded-sm px-2 py-1.5 -mx-2' : 'opacity-80']) { @subtitle }
  end
end
