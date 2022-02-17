FactoryBot.define do
  factory :article do
    title { "MyText" }
    description { "MyText" }
    published { "2022-02-16" }
    is_draft { true }
  end
end
