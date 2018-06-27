class FindContactsController < ApplicationController
	before_action :authenticate_user!


	def index
		@user = User.find(current_user.id)
  		@company = ClientCompany.find_by(id: @user.client_company_id)
    	# grab reports and grab leads for every week for a report
    	@queries = FindContact.where(client_company_id: @company.id).order('updated_at DESC').paginate(:page => params[:page], :per_page => 20)
	end


	def new
		@query = FindContact.new
	end


	def create
		@user = User.find(current_user.id)
    	@company = ClientCompany.find_by(id: @user.client_company_id)

    	@query = FindContact.new(query_params)
    	@query.client_company = @company

    	if  @query.save
    		
			redirect_to find_contacts_path, :notice => "Your job is executing!"
			return
		else
			redirect_to find_contacts_path, :notice => "Could not execute job!"
			return
		end

	end


	private


	def query_params
      params.require(:find_company).permit(:source, :url, :keywords, :location)
	end



end
