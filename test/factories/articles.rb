FactoryBot.define do
  factory :article do
    title { "No D&D session this week!" }
    body { "We regret to inform you that this week's D&D session has been cancelled, the DM's dog has eaten a key NPC's character sheet, bad Fido! We'll be back in a fortnight!" }
    published_at { "2022-02-16" }
    is_draft { true }
  end
end
