# == Schema Information
#
# Table name: journal_entries
#
#  id                        :bigint           not null, primary key
#  idempotency_key           :string           not null
#  memo                      :string
#  posted_at                 :datetime         not null
#  source_type               :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  reverses_journal_entry_id :bigint
#  source_id                 :bigint
#
# Indexes
#
#  index_journal_entries_on_idempotency_key            (idempotency_key) UNIQUE
#  index_journal_entries_on_reverses_journal_entry_id  (reverses_journal_entry_id) UNIQUE
#  index_journal_entries_on_source_type_and_source_id  (source_type,source_id)
#
# Foreign Keys
#
#  fk_rails_...  (reverses_journal_entry_id => journal_entries.id)
#
require "rails_helper"

RSpec.describe JournalEntry do
  subject { build(:journal_entry) }

  it { is_expected.to validate_presence_of(:idempotency_key) }
  it { is_expected.to validate_presence_of(:posted_at) }
  it { is_expected.to belong_to(:reverses).class_name("JournalEntry").optional }
  it { is_expected.to belong_to(:source).optional }
  it { is_expected.to have_many(:postings) }

  describe "debits_must_equal_credits" do
    let(:wallet)  { create(:account) }
    let(:revenue) { create(:account, :system_revenue) }

    it "is valid when debits equal credits" do
      je = build(:journal_entry)
      je.postings.build(account: wallet,  direction: "debit",  amount_cents: 1000, currency: "USD")
      je.postings.build(account: revenue, direction: "credit", amount_cents: 1000, currency: "USD")
      expect(je).to be_valid
    end

    it "is invalid when debits do not equal credits" do
      je = build(:journal_entry)
      je.postings.build(account: wallet,  direction: "debit",  amount_cents: 1000, currency: "USD")
      je.postings.build(account: revenue, direction: "credit", amount_cents:  999, currency: "USD")
      expect(je).not_to be_valid
      expect(je.errors[:base].join).to match(/debits.*must equal credits/)
    end
  end

  describe "immutability" do
    let!(:journal_entry) { create(:journal_entry) }

    it "raises on update" do
      expect { journal_entry.update!(memo: "changed") }.to raise_error(JournalEntry::ImmutableError)
    end

    it "raises on destroy" do
      expect { journal_entry.destroy! }.to raise_error(JournalEntry::ImmutableError)
    end
  end

  describe "unique reverses_journal_entry_id" do
    it "rejects two entries reversing the same entry" do
      original = create(:journal_entry)
      create(:journal_entry, reverses: original)

      expect {
        create(:journal_entry, reverses: original)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
