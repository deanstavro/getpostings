class FindCompany < ApplicationRecord
	 enum source: ["search by location", "search by job postings"]
	 belongs_to :user

	 


	def active?
    	status == 'active'
  	end

end
