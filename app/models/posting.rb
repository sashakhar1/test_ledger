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
