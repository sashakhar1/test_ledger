FactoryBot.define do
  factory :account do
    association :user
    kind { "user_wallet" }
    currency { "USD" }

    trait :system_revenue do
      user { nil }
      kind { "system_revenue" }
    end

    trait :system_clearing do
      user { nil }
      kind { "system_clearing" }
    end
  end
end
