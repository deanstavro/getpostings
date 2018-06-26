class Addstatustoqueries < ActiveRecord::Migration[5.0]
  def change
  	add_column :queries, :status, :string
  end
end
