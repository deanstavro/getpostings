class Addstatustoqueries < ActiveRecord::Migration[5.0]
  def change
  	add_column :find_companies, :status, :string
  end
end
