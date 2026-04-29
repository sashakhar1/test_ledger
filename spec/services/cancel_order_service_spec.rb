require "rails_helper"

RSpec.describe CancelOrderService do
  let(:user)     { create(:user) }
  let!(:wallet)  { create(:account, user: user, kind: "user_wallet") }
  let!(:revenue) { create(:account, :system_revenue) }

  describe "cancelling an unpaid (created) order" do
    let(:order) { create(:order, user: user, amount_cents: 1000, status: "created") }

    it "transitions order to cancelled" do
      CancelOrderService.call(order: order)
      expect(order.reload.status).to eq("cancelled")
    end

    it "creates no journal entry" do
      expect { CancelOrderService.call(order: order) }.not_to change(JournalEntry, :count)
    end

    it "leaves cancellation_journal_entry nil" do
      CancelOrderService.call(order: order)
      expect(order.reload.cancellation_journal_entry).to be_nil
    end

    it "does not change wallet balance" do
      expect { CancelOrderService.call(order: order) }.not_to change { wallet.reload.balance_cents }
    end
  end

  describe "cancelling a paid order (storno)" do
    let(:order) { create(:order, user: user, amount_cents: 1000) }

    before { PayOrderService.call(order: order) }

    it "transitions order to cancelled" do
      CancelOrderService.call(order: order)
      expect(order.reload.status).to eq("cancelled")
    end

    it "creates a reversing JournalEntry" do
      expect { CancelOrderService.call(order: order) }.to change(JournalEntry, :count).by(1)
    end

    it "links the storno to the original via reverses_journal_entry_id" do
      original_id = order.paid_journal_entry_id
      CancelOrderService.call(order: order)
      storno = order.reload.cancellation_journal_entry
      expect(storno.reverses_journal_entry_id).to eq(original_id)
    end

    it "tags the storno with deterministic idempotency key" do
      CancelOrderService.call(order: order)
      expect(order.reload.cancellation_journal_entry.idempotency_key).to eq("order:#{order.id}:cancel")
    end

    it "produces postings on the same accounts with flipped direction and same amount" do
      CancelOrderService.call(order: order)
      original_postings = order.reload.paid_journal_entry.postings
      storno_postings   = order.cancellation_journal_entry.postings

      original_postings.each do |op|
        match = storno_postings.find { |sp| sp.account_id == op.account_id }
        expect(match).to be_present
        expect(match.amount_cents).to eq(op.amount_cents)
        expect(match.direction).to eq(op.direction == "debit" ? "credit" : "debit")
      end
    end

    it "returns wallet balance back to zero" do
      CancelOrderService.call(order: order)
      expect(wallet.reload.balance_cents).to eq(0)
    end

    it "returns revenue balance back to zero" do
      CancelOrderService.call(order: order)
      expect(revenue.reload.balance_cents).to eq(0)
    end

    it "does not modify the original JournalEntry" do
      original_je = order.reload.paid_journal_entry
      original_attrs   = original_je.attributes
      original_posting_ids = original_je.posting_ids.sort

      CancelOrderService.call(order: order)
      original_je.reload

      expect(original_je.attributes).to eq(original_attrs)
      expect(original_je.posting_ids.sort).to eq(original_posting_ids)
    end

    it "does not modify the original postings" do
      original_postings_snapshot = order.reload.paid_journal_entry.postings.map(&:attributes)

      CancelOrderService.call(order: order)
      order.reload.paid_journal_entry.postings.reload

      expect(order.paid_journal_entry.postings.map(&:attributes)).to eq(original_postings_snapshot)
    end
  end

  describe "idempotency on paid order" do
    let(:order) { create(:order, user: user, amount_cents: 1000) }

    before do
      PayOrderService.call(order: order)
      CancelOrderService.call(order: order)
    end

    it "second cancel creates no new JournalEntry" do
      expect { CancelOrderService.call(order: order) }.not_to change(JournalEntry, :count)
    end

    it "second cancel does not raise" do
      expect { CancelOrderService.call(order: order) }.not_to raise_error
    end

    it "wallet balance stays at zero" do
      CancelOrderService.call(order: order)
      expect(wallet.reload.balance_cents).to eq(0)
    end
  end

  describe "idempotency on unpaid order" do
    let(:order) { create(:order, user: user, status: "created") }

    before { CancelOrderService.call(order: order) }

    it "second cancel does not raise" do
      expect { CancelOrderService.call(order: order) }.not_to raise_error
    end
  end

  describe "double-storno protection" do
    it "rejects creating a second reversing entry against the same original at DB level" do
      order = create(:order, user: user, amount_cents: 1000)
      PayOrderService.call(order: order)
      original_je = order.reload.paid_journal_entry

      CancelOrderService.call(order: order)

      duplicate = JournalEntry.new(
        idempotency_key: "manual:test:#{order.id}",
        posted_at: Time.current,
        reverses: original_je
      )

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
