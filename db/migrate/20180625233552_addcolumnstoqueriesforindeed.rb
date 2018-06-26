class Addcolumnstoqueriesforindeed < ActiveRecord::Migration[5.0]
  def change
  	add_column :queries, :keywords, :string
  	add_column :queries, :location, :string

  end
end
