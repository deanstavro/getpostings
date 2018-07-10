class Account < ApplicationRecord
	has_many :leads
	belongs_to :user, optional: false

	validates_uniqueness_of :website, scope: :client_company_id
	validates :name, presence: true, allow_blank: false
	validates :website, presence: true, allow_blank: false
	validates :status, presence: true, allow_blank: false

	enum status: [:cold, :in_campaign, :blacklist, :customer]
end
