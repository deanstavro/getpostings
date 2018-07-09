class Addfieldstofindcontact < ActiveRecord::Migration[5.0]
  def change
  	add_column :find_contacts, :seniority, :string
  	add_column :find_contacts, :department, :string
  end
end
