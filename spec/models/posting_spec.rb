require "rails_helper"

RSpec.describe Posting do
  subject { build(:posting) }

  it { is_expected.to belong_to(:journal_entry) }
  it { is_expected.to belong_to(:account) }
  it { is_expected.to validate_presence_of(:direction) }
  it { is_expected.to validate_inclusion_of(:direction).in_array(Posting::DIRECTIONS) }
  it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than(0) }
  it { is_expected.to validate_presence_of(:currency) }

  describe "immutability" do
    let!(:posting) { create(:posting) }

    it "raises on update" do
      expect { posting.update!(amount_cents: 999) }.to raise_error(Posting::ImmutableError)
    end

    it "raises on destroy" do
      expect { posting.destroy! }.to raise_error(Posting::ImmutableError)
    end
  end
end
