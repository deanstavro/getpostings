ActiveAdmin.register ClientCompany do
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
permit_params  :name, :description, :company_notes, :company_domain, :airtable_keys, :replyio_keys, :api_key, :number_of_seats, :emails_to_use, :products, :notable_clients, :profile_setup, :account_live, :account_manager
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end

end
