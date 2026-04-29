# == Schema Information
#
# Table name: accounts
#
#  id            :bigint           not null, primary key
#  balance_cents :bigint           default(0), not null
#  currency      :string           default("USD"), not null
#  kind          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint
#
# Indexes
#
#  index_accounts_on_user_id           (user_id)
#  index_accounts_on_user_id_and_kind  (user_id,kind)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Account < ApplicationRecord
  ACTIVE_KINDS  = %w[user_wallet system_clearing].freeze
  PASSIVE_KINDS = %w[system_revenue].freeze
  KINDS = (ACTIVE_KINDS + PASSIVE_KINDS).freeze

  belongs_to :user, optional: true
  has_many :postings

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :currency, presence: true

  def active?
    ACTIVE_KINDS.include?(kind)
  end

  def recalculated_balance_cents
    debit_sum  = postings.where(direction: "debit").sum(:amount_cents)
    credit_sum = postings.where(direction: "credit").sum(:amount_cents)
    active? ? debit_sum - credit_sum : credit_sum - debit_sum
  end
end
