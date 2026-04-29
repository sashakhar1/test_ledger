class User < ApplicationRecord
  has_many :accounts
  has_many :orders

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
end
