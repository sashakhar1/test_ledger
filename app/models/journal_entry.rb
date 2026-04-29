class JournalEntry < ApplicationRecord
  class ImmutableError < StandardError; end

  has_many :postings, inverse_of: :journal_entry
  belongs_to :reverses,
             class_name: "JournalEntry",
             foreign_key: :reverses_journal_entry_id,
             optional: true
  has_one :reversed_by,
          class_name: "JournalEntry",
          foreign_key: :reverses_journal_entry_id
  belongs_to :source, polymorphic: true, optional: true

  validates :idempotency_key, presence: true
  validates :posted_at, presence: true
  validate :debits_must_equal_credits

  before_update { raise ImmutableError, "JournalEntry is append-only" }
  before_destroy { raise ImmutableError, "JournalEntry is append-only" }

  private

  def debits_must_equal_credits
    debit  = postings.select { |p| p.direction == "debit"  }.sum(&:amount_cents)
    credit = postings.select { |p| p.direction == "credit" }.sum(&:amount_cents)
    return if debit == credit

    errors.add(:base, "debits (#{debit}) must equal credits (#{credit})")
  end
end

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
