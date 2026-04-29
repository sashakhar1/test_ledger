class CancelOrderService
  class CorruptedOrderState < StandardError; end
  class AccountNotFound     < StandardError; end

  def self.call(order:)
    new(order:).call
  end

  def initialize(order:)
    @order = order
  end

  def call
    return @order.reload if @order.status == "cancelled"

    case @order.status
    when "created"
      cancel_unpaid_order
    when "paid"
      return @order.reload if storno_already_exists?
      cancel_paid_order_with_storno
    else
      raise Order::InvalidStateTransition,
            "Cannot cancel Order ##{@order.id} in status #{@order.status.inspect}"
    end

    @order
  rescue ActiveRecord::RecordNotUnique => e
    raise unless e.message.include?("idempotency_key") || e.message.include?("reverses_journal_entry_id")

    @order.reload
  end

  private

  def cancel_unpaid_order
    @order.transition_to!("cancelled")
    @order.save!
  end

  def cancel_paid_order_with_storno
    original_je = @order.paid_journal_entry
    raise CorruptedOrderState, "Order ##{@order.id} is paid but has no paid_journal_entry" unless original_je

    wallet = locate_user_wallet

    wallet.with_lock do
      storno_je = build_storno(original_je)
      storno_je.save!

      original_je.postings.map(&:account).uniq.each { |acc| refresh_balance(acc) }

      @order.transition_to!("cancelled")
      @order.cancellation_journal_entry = storno_je
      @order.save!
    end
  end

  def storno_already_exists?
    JournalEntry.exists?(idempotency_key: cancel_idempotency_key)
  end

  def cancel_idempotency_key
    "order:#{@order.id}:cancel"
  end

  def locate_user_wallet
    @order.user.accounts.find_by(kind: "user_wallet", currency: @order.currency) ||
      raise(AccountNotFound, "user_wallet not found for User ##{@order.user_id} (#{@order.currency})")
  end

  def build_storno(original_je)
    storno = JournalEntry.new(
      idempotency_key: cancel_idempotency_key,
      memo: "Order ##{@order.id} cancelled (storno of JE ##{original_je.id})",
      reverses: original_je,
      source: @order,
      posted_at: Time.current
    )
    original_je.postings.each do |original_posting|
      storno.postings.build(
        account: original_posting.account,
        direction: opposite_direction(original_posting.direction),
        amount_cents: original_posting.amount_cents,
        currency: original_posting.currency
      )
    end
    storno
  end

  def opposite_direction(direction)
    direction == "debit" ? "credit" : "debit"
  end

  def refresh_balance(account)
    account.update!(balance_cents: account.recalculated_balance_cents)
  end
end
