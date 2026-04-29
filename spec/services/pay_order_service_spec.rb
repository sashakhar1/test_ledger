require "rails_helper"

RSpec.describe PayOrderService do
  let(:user)     { create(:user) }
  let!(:wallet)  { create(:account, user: user, kind: "user_wallet") }
  let!(:revenue) { create(:account, :system_revenue) }

  describe "happy path" do
    let(:order) { create(:order, user: user, amount_cents: 1000) }

    it "transitions the order to paid" do
      PayOrderService.call(order: order)
      expect(order.reload.status).to eq("paid")
    end

    it "creates a single JournalEntry with two postings" do
      expect { PayOrderService.call(order: order) }.to change(JournalEntry, :count).by(1)

      je = JournalEntry.last
      expect(je.postings.count).to eq(2)
      expect(je.postings.where(direction: "debit").sum(:amount_cents)).to eq(1000)
      expect(je.postings.where(direction: "credit").sum(:amount_cents)).to eq(1000)
    end

    it "links the order to the journal entry" do
      PayOrderService.call(order: order)
      expect(order.reload.paid_journal_entry).to be_present
    end

    it "tags the journal entry with deterministic idempotency key" do
      PayOrderService.call(order: order)
      expect(JournalEntry.last.idempotency_key).to eq("order:#{order.id}:pay")
    end

    it "increases wallet balance by amount_cents (active account, debit side)" do
      expect { PayOrderService.call(order: order) }
        .to change { wallet.reload.balance_cents }.by(1000)
    end

    it "increases revenue balance by amount_cents (passive account, credit side)" do
      expect { PayOrderService.call(order: order) }
        .to change { revenue.reload.balance_cents }.by(1000)
    end
  end

  describe "idempotency" do
    let(:order) { create(:order, user: user, amount_cents: 1000) }

    before { PayOrderService.call(order: order) }

    it "second call does not create a new journal entry" do
      expect { PayOrderService.call(order: order) }.not_to change(JournalEntry, :count)
    end

    it "second call does not double-charge the wallet" do
      expect { PayOrderService.call(order: order) }.not_to change { wallet.reload.balance_cents }
    end

    it "second call returns the order without raising" do
      expect { PayOrderService.call(order: order) }.not_to raise_error
    end
  end

  describe "illegal transitions" do
    it "raises when order is already cancelled" do
      order = create(:order, user: user, status: "cancelled")
      expect { PayOrderService.call(order: order) }
        .to raise_error(Order::InvalidStateTransition)
    end

    it "raises when order is already paid by external code (no idempotency JE)" do
      order = create(:order, user: user, status: "paid")
      expect { PayOrderService.call(order: order) }
        .to raise_error(Order::InvalidStateTransition)
    end

    it "raises when paying an order that was paid then cancelled (storno cycle)" do
      order = create(:order, user: user, amount_cents: 1000)
      PayOrderService.call(order: order)
      CancelOrderService.call(order: order)

      expect { PayOrderService.call(order: order) }
        .to raise_error(Order::InvalidStateTransition)
    end
  end

  describe "missing accounts" do
    it "raises AccountNotFound when user has no wallet" do
      walletless_user = create(:user)
      order = create(:order, user: walletless_user, amount_cents: 1000)
      expect { PayOrderService.call(order: order) }
        .to raise_error(PayOrderService::AccountNotFound, /user_wallet/)
    end

    it "raises AccountNotFound when system_revenue is missing" do
      revenue.destroy
      order = create(:order, user: user, amount_cents: 1000)
      expect { PayOrderService.call(order: order) }
        .to raise_error(PayOrderService::AccountNotFound, /system_revenue/)
    end
  end
end
