# frozen_string_literal: true

# TODO(#3163): Move to app/directory/components/directory_partner_sidebar.rb
class Components::DirectoryPartnerSidebar < Components::Base
  prop :partner, ::Partner
  prop :containing_sites, _Interface(:each), default: -> { [] }

  def view_template
    div(class: 'bg-home-background-3 rounded-[1rem] p-5 mb-6') do
      render_partnerships if Array(@containing_sites).any?
      render_categories if @partner.categories.any?
      render_neighbourhood
    end
  end

  private

  def render_partnerships
    div(class: 'mb-5') do
      h4(class: 'text-[0.72rem] font-extra-bold uppercase tracking-wide text-tertiary mb-2') do
        plain "Part of #{Array(@containing_sites).size} #{'partnership'.pluralize(Array(@containing_sites).size)}"
      end
      div(class: 'flex flex-col gap-1.5') do
        Array(@containing_sites).each do |site|
          a(href: partnership_path(site),
            class: 'inline-flex items-center gap-2 py-1.5 px-3 rounded-full border-2 border-rules text-sm font-bold text-foreground no-underline hover:border-foreground transition-colors') do
            plain site.name
            span(class: 'text-tertiary text-xs') { safe('&rarr;') }
          end
        end
      end
    end
  end

  def render_categories
    div(class: 'mb-5') do
      h4(class: 'text-[0.72rem] font-extra-bold uppercase tracking-wide text-tertiary mb-2') { 'Categories' }
      div(class: 'flex flex-wrap gap-1.5') do
        @partner.categories.each do |cat|
          a(href: partners_path(category: cat.id),
            class: 'inline-flex items-center bg-primary-light text-foreground text-[0.72rem] font-bold rounded-full px-2.5 py-0.5 no-underline hover:bg-primary transition-colors') do
            plain cat.name
          end
        end
      end
    end
  end

  def render_neighbourhood
    return unless @partner.address&.neighbourhood

    div do
      h4(class: 'text-[0.72rem] font-extra-bold uppercase tracking-wide text-tertiary mb-2') { 'Neighbourhood' }
      neighbourhood = @partner.address.neighbourhood
      path = neighbourhood.path
      div(class: 'text-sm text-tertiary') do
        path.each_with_index do |ancestor, i|
          plain ' > ' if i.positive?
          span(class: 'text-foreground font-bold') { ancestor.name } if ancestor == neighbourhood
          plain(ancestor.name) if ancestor != neighbourhood
        end
      end
    end
  end
end
