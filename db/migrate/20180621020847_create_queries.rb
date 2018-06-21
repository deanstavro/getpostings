class CreateQueries < ActiveRecord::Migration[5.0]
  def change
    create_table :queries do |t|
      t.integer :source
      t.string :url
      t.string :file_download

      t.timestamps
    end
  end
end
