require "rails_helper"

RSpec.describe Order do
  subject { build(:order) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:paid_journal_entry).class_name("JournalEntry").optional }
  it { is_expected.to belong_to(:cancellation_journal_entry).class_name("JournalEntry").optional }

  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to validate_inclusion_of(:status).in_array(Order::STATUSES) }
  it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than(0) }
  it { is_expected.to validate_presence_of(:currency) }

  it "defaults status to 'created'" do
    expect(Order.new.status).to eq("created")
  end

  describe "#transition_to!" do
    it "created -> paid is allowed" do
      order = build(:order, status: "created")
      order.transition_to!("paid")
      expect(order.status).to eq("paid")
    end

    it "created -> cancelled is allowed" do
      order = build(:order, status: "created")
      order.transition_to!("cancelled")
      expect(order.status).to eq("cancelled")
    end

    it "paid -> cancelled is allowed" do
      order = build(:order, status: "paid")
      order.transition_to!("cancelled")
      expect(order.status).to eq("cancelled")
    end

    it "paid -> paid raises" do
      order = build(:order, status: "paid")
      expect { order.transition_to!("paid") }.to raise_error(Order::InvalidStateTransition)
    end

    it "cancelled -> paid raises" do
      order = build(:order, status: "cancelled")
      expect { order.transition_to!("paid") }.to raise_error(Order::InvalidStateTransition)
    end

    it "cancelled -> cancelled raises" do
      order = build(:order, status: "cancelled")
      expect { order.transition_to!("cancelled") }.to raise_error(Order::InvalidStateTransition)
    end

    it "raises on unknown target status" do
      order = build(:order, status: "created")
      expect { order.transition_to!("voodoo") }.to raise_error(Order::InvalidStateTransition)
    end
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
