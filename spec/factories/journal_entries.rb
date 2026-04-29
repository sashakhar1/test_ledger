FactoryBot.define do
  factory :journal_entry do
    sequence(:idempotency_key) { |n| "ik_#{n}" }
    memo { "Test entry" }
    posted_at { Time.current }
  end
end
