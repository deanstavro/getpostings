class AddCampaignsToClientComapnies < ActiveRecord::Migration[5.0]
  def change
    add_reference :leads, :client_company, foreign_key: true
  end
end
