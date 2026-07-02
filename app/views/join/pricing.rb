# frozen_string_literal: true

class Views::Join::Pricing < Views::Join::Base
  def view_template
    content_for(:title) { t('join.pricing.title') }

    section(class: 'py-10') do
      div(class: 'container-public') do
        breadcrumb([t('join.nav.pricing')])
        div(class: 'text-center mb-8') do
          h1(class: 'join-headline m-0 mb-2') { t('join.pricing.title') }
          p(class: 'text-base text-tertiary leading-relaxed max-w-(--width-prose-md) mx-auto m-0') { t('join.pricing.lede') }
        end
        div(class: 'grid md:grid-cols-3 gap-4 items-start') do
          render_card(:community)
          render_card(:partnership, featured: true)
          render_card(:metropolitan)
        end
        p(class: 'text-center text-detail text-tertiary mt-6 mb-0') { t('join.pricing.footnote') }
      end
    end
  end

  private

  def render_card(plan, featured: false)
    border = featured ? 'border-[3px] border-secondary-deep' : 'border-2 border-rules'
    div(class: "bg-home-background rounded-card p-6 #{border}") do
      h2(class: 'font-serif font-regular text-card text-foreground m-0') { t("join.pricing.#{plan}.name") }
      div(class: 'font-serif text-[2.4rem] leading-none text-foreground my-3') { t("join.pricing.#{plan}.price") }
      p(class: 'text-sm text-tertiary leading-normal mt-0 mb-3') { t("join.pricing.#{plan}.blurb") }
      ul(class: 'list-none p-0 m-0') do
        t("join.pricing.#{plan}.items").each do |item|
          li(class: 'py-1.5 border-b border-rules text-detail flex gap-2 items-start') do
            span(class: 'text-secondary-deep mt-0.5') { icon(:check, size: '4') }
            span { item }
          end
        end
      end
      render_cta(plan) if featured
    end
  end

  def render_cta(plan)
    div(class: 'mt-4') do
      a(href: join_demo_path, class: 'btn-join w-full justify-center') { t("join.pricing.#{plan}.cta") }
    end
  end
end
