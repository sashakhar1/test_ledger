FactoryBot.define do
  factory :posting do
    association :journal_entry
    association :account
    direction { "debit" }
    amount_cents { 1000 }
    currency { "USD" }
  end
end
