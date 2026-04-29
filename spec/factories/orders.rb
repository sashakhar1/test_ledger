FactoryBot.define do
  factory :order do
    association :user
    amount_cents { 1000 }
    currency { "USD" }
    status { "created" }
  end
end

# == Schema Information
#
# Table name: orders
#
#  id                            :bigint           not null, primary key
#  amount_cents                  :bigint           not null
#  currency                      :string           default("USD"), not null
#  status                        :string           default("created"), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  cancellation_journal_entry_id :bigint
#  paid_journal_entry_id         :bigint
#  user_id                       :bigint           not null
#
# Indexes
#
#  index_orders_on_cancellation_journal_entry_id  (cancellation_journal_entry_id)
#  index_orders_on_paid_journal_entry_id          (paid_journal_entry_id)
#  index_orders_on_status                         (status)
#  index_orders_on_user_id                        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (cancellation_journal_entry_id => journal_entries.id)
#  fk_rails_...  (paid_journal_entry_id => journal_entries.id)
#  fk_rails_...  (user_id => users.id)
#
