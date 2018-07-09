class FindContact < ApplicationRecord
	belongs_to :client_company





	def self.find_contacts(file, company, leads, campaign_id, column_names)
		
		puts "Starting importing to campaign"


		AddContactsToReplyJob.perform_later(all_hash,campaign_id)

		return imported.to_s + " leads imported successfully, duplicate lead rows not uploaded: "+ duplicates.to_s + ", " + rows_email_not_present.to_s + " rows without email field"
	end



end
