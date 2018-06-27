class CreateFindContacts < ActiveRecord::Migration[5.0]
  def change
    create_table :find_contacts do |t|
      t.string :csv_file
      t.string :download_file

      t.timestamps
    end

    add_reference :find_contacts, :client_company, foreign_key: true
  end
end
