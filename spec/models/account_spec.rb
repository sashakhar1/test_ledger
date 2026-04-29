require "rails_helper"

RSpec.describe Account do
  subject { build(:account) }

  it { is_expected.to belong_to(:user).optional }
  it { is_expected.to validate_presence_of(:kind) }
  it { is_expected.to validate_inclusion_of(:kind).in_array(Account::KINDS) }
  it { is_expected.to validate_presence_of(:currency) }

  it "defaults balance_cents to 0" do
    expect(Account.new.balance_cents).to eq(0)
  end

  it "defaults currency to USD" do
    expect(Account.new.currency).to eq("USD")
  end
end
