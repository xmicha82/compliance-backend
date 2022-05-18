# frozen_string_literal: true

# Represents a Insights account. An account can be composed of many users
class Account < ApplicationRecord
  has_many :users, dependent: :nullify
  # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :hosts, foreign_key: :account, primary_key: :account_number,
                   inverse_of: :account_object
  # rubocop:enable Rails/HasManyOrHasOneDependent
  has_many :profiles, dependent: :destroy
  has_many :policies, dependent: :destroy
  has_many :business_objectives, through: :policies

  validates :account_number, presence: true, allow_blank: false

  class << self
    def from_identity_header(identity_header)
      # FIXME: swap the 'account_number' with the 'org_id' after the translation is done
      account = Account.find_or_create_by(
        account_number: identity_header.identity['account_number']
      )

      # Update the 'is_internal' and the 'org_id' fields if set and differs
      updates = {
        is_internal: (identity_header.is_internal unless identity_header.is_internal.nil?),
        org_id: (identity_header.identity['org_id'] if account.org_id.blank?)
      }.compact

      account.update!(updates) if updates.any?
      account
    end
  end

  # rubocop:disable Metrics/MethodLength
  def fake_identity_header
    {
      'identity': {
        'account_number': account_number,
        'org_id': org_id,
        'type': 'User',
        'auth_type': 'basic-auth',
        'user': {
          'username': 'ComplianceSyncJob',
          'email': 'no-reply@redhat.com',
          'first_name': 'Compliance',
          'last_name': 'Team',
          'is_active': true,
          'is_internal': true,
          'is_org_admin': true,
          'locale': 'en_US'
        }
      }
    }
  end
  # rubocop:enable Metrics/MethodLength

  def b64_identity
    Base64.strict_encode64(fake_identity_header.to_json)
  end
end
