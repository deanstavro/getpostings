class AddReferenceToClientCompanies < ActiveRecord::Migration[5.0]
  def change
  	add_reference :queries, :client_company, foreign_key: true
  end
end
