class PayOrderService
  class AccountNotFound < StandardError; end

  def self.call(order:)
    new(order:).call
  end

  def initialize(order:)
    @order = order
  end

  def call
    return @order if already_paid? && @order.reload.status == "paid"

    unless @order.status == "created"
      raise Order::InvalidStateTransition,
            "Cannot pay Order ##{@order.id} in status #{@order.status.inspect}"
    end

    wallet  = locate_user_wallet
    revenue = locate_system_revenue

    # Defence in depth: the UNIQUE constraint on JournalEntry#idempotency_key
    # already blocks double-charging on retries. This lock additionally
    # serialises balance recalculation under contention.
    wallet.with_lock do
      journal_entry = build_journal_entry(wallet:, revenue:)
      journal_entry.save!

      refresh_balance(wallet)
      refresh_balance(revenue)

      @order.transition_to!("paid")
      @order.paid_journal_entry = journal_entry
      @order.save!
    end

    @order
  rescue ActiveRecord::RecordNotUnique => e
    raise unless e.message.include?("idempotency_key")

    @order.reload
  end

  private

  def already_paid?
    JournalEntry.exists?(idempotency_key:)
  end

  def idempotency_key
    "order:#{@order.id}:pay"
  end

  def locate_user_wallet
    @order.user.accounts.find_by(kind: "user_wallet", currency: @order.currency) ||
      raise(AccountNotFound, "user_wallet not found for User ##{@order.user_id} (#{@order.currency})")
  end

  def locate_system_revenue
    Account.find_by(kind: "system_revenue", currency: @order.currency) ||
      raise(AccountNotFound, "system_revenue account not found (#{@order.currency})")
  end

  def build_journal_entry(wallet:, revenue:)
    je = JournalEntry.new(
      idempotency_key:,
      memo: "Order ##{@order.id} paid",
      source: @order,
      posted_at: Time.current
    )
    je.postings.build(account: wallet,  direction: "debit",  amount_cents: @order.amount_cents, currency: @order.currency)
    je.postings.build(account: revenue, direction: "credit", amount_cents: @order.amount_cents, currency: @order.currency)
    je
  end

  def refresh_balance(account)
    account.update!(balance_cents: account.recalculated_balance_cents)
  end
end
