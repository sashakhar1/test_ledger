require "rails_helper"

RSpec.describe "Concurrency" do
  self.use_transactional_tests = false

  # Transactional fixtures are off here so parallel threads can see each other's
  # committed writes; without them we have to wipe state ourselves between examples.
  def truncate_all_tables
    ActiveRecord::Base.connection.execute(
      "TRUNCATE TABLE postings, orders, journal_entries, accounts, users RESTART IDENTITY CASCADE"
    )
  end

  before { truncate_all_tables }
  after  { truncate_all_tables }

  describe "two threads paying the same order in parallel" do
    let(:user)     { create(:user) }
    let!(:wallet)  { create(:account, user: user, kind: "user_wallet") }
    let!(:revenue) { create(:account, :system_revenue) }
    let(:order)    { create(:order, user: user, amount_cents: 1000) }

    it "produces exactly one JournalEntry and a correct balance" do
      order_id = order.id

      threads = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            PayOrderService.call(order: Order.find(order_id))
          rescue Order::InvalidStateTransition, ActiveRecord::RecordNotUnique
            nil
          end
        end
      end

      threads.each(&:join)

      expect(JournalEntry.where(idempotency_key: "order:#{order_id}:pay").count).to eq(1)
      expect(Order.find(order_id).status).to eq("paid")
      expect(wallet.reload.balance_cents).to eq(1000)
      expect(revenue.reload.balance_cents).to eq(1000)
      expect(Posting.where(account_id: wallet.id).count).to eq(1)
    end
  end

  describe "two threads paying two different orders for the same wallet" do
    let(:user)     { create(:user) }
    let!(:wallet)  { create(:account, user: user, kind: "user_wallet") }
    let!(:revenue) { create(:account, :system_revenue) }

    it "serialises through the wallet lock and both orders end paid" do
      order_a = create(:order, user: user, amount_cents: 700)
      order_b = create(:order, user: user, amount_cents: 300)

      threads = [order_a.id, order_b.id].map do |order_id|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            PayOrderService.call(order: Order.find(order_id))
          end
        end
      end

      threads.each(&:join)

      expect(Order.find(order_a.id).status).to eq("paid")
      expect(Order.find(order_b.id).status).to eq("paid")
      expect(wallet.reload.balance_cents).to eq(1000)
      expect(JournalEntry.count).to eq(2)
    end
  end
end
