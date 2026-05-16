# frozen_string_literal: true

class Components::Directory::PageHero < Components::Directory::Base
  prop :title, String
  prop :kicker, _Nilable(String), default: nil
  prop :subtitle, _Nilable(String), default: nil
  prop :breadcrumb_label, _Nilable(String), default: nil

  def view_template
    section(class: 'bg-foreground pt-3 pb-5', style: 'color: var(--color-background)') do
      div(class: 'container-public') do
        render_breadcrumb if @breadcrumb_label
        render_kicker if @kicker
        h1(class: 'font-serif font-regular text-hero leading-hero') { @title }
        p(class: 'text-base leading-relaxed max-w-[700px] mt-3 opacity-80') { @subtitle } if @subtitle
      end
    end
  end

  private

  def render_breadcrumb
    nav(class: 'text-sm mb-3', style: 'color: var(--color-background)', aria_label: 'Breadcrumb') do
      a(href: root_path, class: 'no-underline hover:underline', style: 'color: inherit') { 'Directory' }
      span(class: 'mx-1.5 opacity-60') { safe('›') }
      span(class: 'opacity-80') { @breadcrumb_label }
    end
  end

  def render_kicker
    p(class: 'allcaps-label mb-1 opacity-80') { @kicker }
  end
end
