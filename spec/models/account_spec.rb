require "rails_helper"

RSpec.describe Account do
  subject { build(:account) }

  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to have_many(:postings) }
  it { is_expected.to validate_presence_of(:kind) }
  it { is_expected.to validate_inclusion_of(:kind).in_array(Account::KINDS) }
  it { is_expected.to validate_presence_of(:currency) }

  it "defaults balance_cents to 0" do
    expect(Account.new.balance_cents).to eq(0)
  end

  it "defaults currency to USD" do
    expect(Account.new.currency).to eq("USD")
  end

  describe "#active?" do
    it "is true for user_wallet" do
      expect(build(:account, kind: "user_wallet").active?).to be true
    end

    it "is true for system_clearing" do
      expect(build(:account, kind: "system_clearing").active?).to be true
    end

    it "is false for system_revenue" do
      expect(build(:account, kind: "system_revenue").active?).to be false
    end
  end

  describe "#recalculated_balance_cents" do
    it "returns 0 when no postings" do
      account = create(:account)
      expect(account.recalculated_balance_cents).to eq(0)
    end

    it "active account: balance = debits minus credits" do
      wallet = create(:account, kind: "user_wallet")
      je = create(:journal_entry)
      create(:posting, journal_entry: je, account: wallet, direction: "debit",  amount_cents: 1000)
      create(:posting, journal_entry: je, account: wallet, direction: "credit", amount_cents:  300)

      expect(wallet.recalculated_balance_cents).to eq(700)
    end

    it "passive account: balance = credits minus debits" do
      revenue = create(:account, :system_revenue)
      je = create(:journal_entry)
      create(:posting, journal_entry: je, account: revenue, direction: "credit", amount_cents: 1000)
      create(:posting, journal_entry: je, account: revenue, direction: "debit",  amount_cents:  300)

      expect(revenue.recalculated_balance_cents).to eq(700)
    end
  end
end
