class Addcolumnstoqueriesforindeed < ActiveRecord::Migration[5.0]
  def change
  	add_column :find_companies, :keywords, :string
  	add_column :find_companies, :location, :string

  end
end
