class AddReferenceToClientCompanies < ActiveRecord::Migration[5.0]
  def change
  	add_reference :find_companies, :user, foreign_key: true
  end
end
