# frozen_string_literal: true

class Components::Directory::PageHero < Components::Directory::Base
  prop :title, String
  prop :kicker, _Nilable(String), default: nil
  prop :subtitle, _Nilable(String), default: nil
  prop :breadcrumb_label, _Nilable(String), default: nil
  prop :breadcrumb_path, _Nilable(String), default: nil
  prop :background_image_url, _Nilable(String), default: nil

  def view_template(&block)
    section(class: 'bg-foreground pt-6 pb-4 relative overflow-hidden', style: 'color: var(--color-background)') do
      render_background_image if @background_image_url
      div(class: 'container-public relative z-10') do
        render_breadcrumb if @breadcrumb_label
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
      style: 'background: linear-gradient(to right, var(--color-foreground) 50%, color-mix(in srgb, var(--color-foreground) 75%, transparent) 62%, color-mix(in srgb, var(--color-foreground) 40%, transparent) 75%, color-mix(in srgb, var(--color-foreground) 15%, transparent) 88%, transparent 100%)'
    )
  end

  def render_breadcrumb
    nav(class: 'text-sm mb-2', style: 'color: var(--color-background)', aria_label: t('directory.aria.breadcrumb')) do
      # root_path is host-relative, so on the join site the trail starts at
      # the join homepage — label it accordingly.
      root_label = join_site_request? ? t('join.breadcrumbs.root') : t('directory.breadcrumbs.root')
      a(href: root_path, class: 'no-underline hover:underline', style: 'color: inherit') { root_label }
      span(class: 'mx-1.5 opacity-60') { safe('›') }
      if @breadcrumb_path
        a(href: @breadcrumb_path, class: 'no-underline hover:underline opacity-80', style: 'color: inherit') { @breadcrumb_label }
      else
        span(class: 'opacity-80') { @breadcrumb_label }
      end
    end
  end

  def render_kicker
    div(class: 'allcaps-label mb-1 opacity-80') { @kicker }
  end

  def render_subtitle
    div(class: "text-base leading-relaxed max-w-(--width-prose-md) mb-2 #{'bg-foreground/80 rounded px-2 py-1.5 -mx-2' if @background_image_url}", style: @background_image_url ? nil : 'opacity: 0.8') { @subtitle }
  end
end
