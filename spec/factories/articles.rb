# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id            :bigint           not null, primary key
#  article_image :string
#  body          :text             not null
#  body_html     :string
#  is_draft      :boolean          default(TRUE), not null
#  published_at  :date
#  slug          :string
#  title         :text             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  author_id     :bigint           not null
#
# Indexes
#
#  index_articles_on_author_id  (author_id)
#  index_articles_on_slug       (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#
FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "Article #{n}" }
    body { Faker::Lorem.paragraphs(number: 5).join("\n\n") }
    is_draft { false }
    published_at { 1.day.ago }
    association :author, factory: :user

    factory :draft_article, aliases: [:article_draft] do
      is_draft { true }
      published_at { nil }
    end

    factory :published_article do
      is_draft { false }
      published_at { 1.day.ago }
    end

    factory :scheduled_article do
      is_draft { false }
      published_at { 1.week.from_now }
    end

    # With partners
    factory :article_with_partners do
      transient do
        partner_count { 2 }
      end

      after(:create) do |article, evaluator|
        evaluator.partner_count.times do
          create(:article_partner, article: article, partner: create(:partner))
        end
      end
    end

    # With tags
    factory :article_with_tags do
      transient do
        tag_count { 2 }
      end

      after(:create) do |article, evaluator|
        evaluator.tag_count.times do
          article.tags << create(:category)
        end
      end
    end
  end

  factory :article_partner do
    association :article
    association :partner
  end
end
