# == Schema Information
#
# Table name: accounts
#
#  id            :bigint           not null, primary key
#  balance_cents :bigint           default(0), not null
#  currency      :string           default("USD"), not null
#  kind          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint
#
# Indexes
#
#  index_accounts_on_user_id           (user_id)
#  index_accounts_on_user_id_and_kind  (user_id,kind)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
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
