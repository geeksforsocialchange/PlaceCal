# frozen_string_literal: true

class Components::Directory::PageHero < Components::Directory::Base
  prop :title, String
  prop :kicker, _Nilable(String), default: nil
  prop :subtitle, _Nilable(String), default: nil
  prop :breadcrumb_label, _Nilable(String), default: nil
  prop :breadcrumb_path, _Nilable(String), default: nil

  def view_template
    section(class: 'bg-foreground pt-6 pb-4', style: 'color: var(--color-background)') do
      div(class: 'container-public') do
        render_breadcrumb if @breadcrumb_label
        render_kicker if @kicker
        h1(class: 'hero-title') { @title }
        div(class: 'text-base leading-relaxed max-w-(--width-prose-md) mt-2 opacity-80') { @subtitle } if @subtitle
      end
    end
  end

  private

  def render_breadcrumb
    nav(class: 'text-sm mb-2', style: 'color: var(--color-background)', aria_label: 'Breadcrumb') do
      a(href: root_path, class: 'no-underline hover:underline', style: 'color: inherit') { 'Directory' }
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
end
