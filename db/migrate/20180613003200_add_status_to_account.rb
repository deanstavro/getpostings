class AddStatusToAccount < ActiveRecord::Migration[5.0]
  def change
  	add_column :accounts, :status, :integer
  	add_reference :accounts, :user, foreign_key: true
  end
end
