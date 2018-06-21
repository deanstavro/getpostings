class Query < ApplicationRecord
	 enum source: [:yelp, :indeed, :yellow_pages]
	 belongs_to :client_company
end
