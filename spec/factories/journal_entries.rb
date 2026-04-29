# == Schema Information
#
# Table name: journal_entries
#
#  id                        :bigint           not null, primary key
#  idempotency_key           :string           not null
#  memo                      :string
#  posted_at                 :datetime         not null
#  source_type               :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  reverses_journal_entry_id :bigint
#  source_id                 :bigint
#
# Indexes
#
#  index_journal_entries_on_idempotency_key            (idempotency_key) UNIQUE
#  index_journal_entries_on_reverses_journal_entry_id  (reverses_journal_entry_id) UNIQUE
#  index_journal_entries_on_source_type_and_source_id  (source_type,source_id)
#
# Foreign Keys
#
#  fk_rails_...  (reverses_journal_entry_id => journal_entries.id)
#
FactoryBot.define do
  factory :journal_entry do
    sequence(:idempotency_key) { |n| "ik_#{n}" }
    memo { "Test entry" }
    posted_at { Time.current }
  end
end
