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
class Posting < ApplicationRecord
  class ImmutableError < StandardError; end

  DIRECTIONS = %w[debit credit].freeze

  belongs_to :journal_entry, inverse_of: :postings
  belongs_to :account

  validates :direction, presence: true, inclusion: { in: DIRECTIONS }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true

  before_update { raise ImmutableError, "Posting is append-only" }
  before_destroy { raise ImmutableError, "Posting is append-only" }
end
