class Account < ApplicationRecord
  KINDS = %w[user_wallet system_revenue system_clearing].freeze

  belongs_to :user, optional: true
  has_many :postings

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :currency, presence: true
end
