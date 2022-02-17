FactoryBot.define do
  factory :article do
    title { "MyText" }
    body { "MyText" }
    published_at { "2022-02-16" }
    is_draft { true }
  end
end
