class CreateFindCompanies < ActiveRecord::Migration[5.0]
  def change
    create_table :find_companies do |t|
      t.integer :source
      t.string :url
      t.string :file_download

      t.timestamps
    end
  end
end
