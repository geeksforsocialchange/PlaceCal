# frozen_string_literal: true

# TODO(#3163): Move to app/directory/components/directory_page_hero.rb
class Components::DirectoryPageHero < Components::Base
  prop :title, String
  prop :kicker, _Nilable(String), default: nil
  prop :subtitle, _Nilable(String), default: nil
  prop :breadcrumb_label, _Nilable(String), default: nil

  def view_template
    section(class: 'pt-4 pb-8') do
      div(class: 'container-public') do
        render_breadcrumb if @breadcrumb_label
        render_kicker if @kicker
        h1(class: 'font-serif font-regular text-[clamp(2rem,4vw,2.8rem)] leading-[1.05] text-foreground') { @title }
        p(class: 'text-tertiary text-base leading-relaxed max-w-[700px] mt-3') { @subtitle } if @subtitle
      end
    end
  end

  private

  def render_breadcrumb
    nav(class: 'text-sm text-tertiary mb-3', aria_label: 'Breadcrumb') do
      a(href: root_path, class: 'text-tertiary no-underline hover:underline') { 'Directory' }
      span(class: 'mx-1.5') { safe('›') }
      span { @breadcrumb_label }
    end
  end

  def render_kicker
    p(class: 'text-[0.72rem] font-extra-bold uppercase tracking-wide text-foreground/80 mb-1') { @kicker }
  end
end
