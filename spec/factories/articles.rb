# frozen_string_literal: true

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
