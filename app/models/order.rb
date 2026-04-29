class Order < ApplicationRecord
  class InvalidStateTransition < StandardError; end

  STATUSES = %w[created paid cancelled].freeze

  ALLOWED_TRANSITIONS = {
    "created"   => %w[paid cancelled],
    "paid"      => %w[cancelled],
    "cancelled" => []
  }.freeze

  belongs_to :user
  belongs_to :paid_journal_entry,
             class_name: "JournalEntry",
             optional: true
  belongs_to :cancellation_journal_entry,
             class_name: "JournalEntry",
             optional: true

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true

  def transition_to!(new_status)
    allowed = ALLOWED_TRANSITIONS.fetch(status, [])
    return self.status = new_status if allowed.include?(new_status)

    raise InvalidStateTransition,
          "Cannot transition Order ##{id} from #{status.inspect} to #{new_status.inspect}"
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
