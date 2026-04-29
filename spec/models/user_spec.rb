require "rails_helper"

RSpec.describe User do
  subject { build(:user) }

  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  it { is_expected.to allow_value("foo@bar.com").for(:email) }
  it { is_expected.not_to allow_value("not-an-email").for(:email) }
end
