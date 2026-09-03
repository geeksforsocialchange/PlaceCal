# frozen_string_literal: true

# == Schema Information
#
# Table name: pages
#
#  id           :bigint           not null, primary key
#  body         :text
#  body_html    :text
#  is_published :boolean          default(FALSE), not null
#  position     :integer          default(0), not null
#  show_in_nav  :boolean          default(FALSE), not null
#  slug         :string           not null
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  site_id      :bigint           not null
#
# Indexes
#
#  index_pages_on_site_id_and_slug  (site_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (site_id => sites.id)
#
FactoryBot.define do
  factory :page do
    association :site
    sequence(:slug) { |n| "page-#{n}" }
    sequence(:title) { |n| "Page #{n}" }
    body { "## About us\n\nWe run a community calendar for everyone." }
    is_published { true }

    factory :draft_page do
      is_published { false }
    end

    factory :nav_page do
      show_in_nav { true }
    end
  end
end
