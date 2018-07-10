class Lead < ApplicationRecord
	require 'csv'
	require 'rest-client'

	belongs_to :user, optional: true
	belongs_to :account, optional: true

	enum status: [:cold, :in_campaign, :not_interested, :blacklist, :interested, :meeting_set]
	#validates :email, presence: true
	
	validates_uniqueness_of :email, scope: :user
	validates :email, presence: true
	validates :first_name, presence: true
	#validates :last_name, presence: true
	after_initialize :init



    def init
      self.contract_amount ||= 0           #will set the default value only if it's nil
      self.contract_sent ||= :no
    end



end
