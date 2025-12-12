# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BreadcrumbComponent, type: :component do
  let(:site_name) { 'Normal Island Central' }
  let(:trail) { [['Partners', '/partners'], ['Events', '/events']] }

  it 'renders site name' do
    render_inline(described_class.new(site_name: site_name, trail: trail))

    expect(page).to have_text(site_name)
  end

  it 'renders breadcrumb trail' do
    render_inline(described_class.new(site_name: site_name, trail: trail))

    expect(page).to have_text('Partners')
    expect(page).to have_text('Events')
  end

  it 'renders links for trail items' do
    render_inline(described_class.new(site_name: site_name, trail: trail))

    expect(page).to have_link('Partners', href: '/partners')
    expect(page).to have_link('Events', href: '/events')
  end

  it 'handles empty trail' do
    render_inline(described_class.new(site_name: site_name, trail: []))

    expect(page).to have_text(site_name)
  end
end
