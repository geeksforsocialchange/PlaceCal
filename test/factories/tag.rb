# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence(:name) do |n|
      "Hulme #{n}"
    end
    slug { name.parameterize }
    description { 'I am a tag' }
    edit_permission { 'root' }

    factory :tag_public, class: :tag do
      description { 'I am a tag everyone can edit' }
      edit_permission { 'all' }
    end

    factory :system_tag do
      system_tag { true }
    end

  end
end
