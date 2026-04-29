FactoryBot.define do
  factory :posting do
    association :journal_entry
    association :account
    direction { "debit" }
    amount_cents { 1000 }
    currency { "USD" }
  end
end

# == Schema Information
#
# Table name: postings
#
#  id               :bigint           not null, primary key
#  amount_cents     :bigint           not null
#  currency         :string           not null
#  direction        :string           not null
#  created_at       :datetime         not null
#  account_id       :bigint           not null
#  journal_entry_id :bigint           not null
#
# Indexes
#
#  index_postings_on_account_id                 (account_id)
#  index_postings_on_account_id_and_created_at  (account_id,created_at)
#  index_postings_on_journal_entry_id           (journal_entry_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (journal_entry_id => journal_entries.id)
#
