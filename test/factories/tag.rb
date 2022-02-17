# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence(:name) do |n|
      "Hulme #{n}"
    end
    slug { name.parameterize }
    description { 'I am a tag' }
    edit_permission { 'root' }

    factory :tag_perms_all, class: :tag do
      description { 'I am a public tag' }
      edit_permission { 'public' }
    end
  end
end
