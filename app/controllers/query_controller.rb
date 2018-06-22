class QueryController < ApplicationController
	before_action :authenticate_user!

	def index
		 @user = User.find(current_user.id)
  		@company = ClientCompany.find_by(id: @user.client_company_id)
    	# grab reports and grab leads for every week for a report
    	@queries = Query.where(client_company_id: @company.id).order('updated_at DESC').paginate(:page => params[:page], :per_page => 20)


	end

	def new
		@query = Query.new
	end

	def create
		@user = User.find(current_user.id)
    	@company = ClientCompany.find_by(id: @user.client_company_id)

    	@query = Query.new(query_params)
    	@query.client_company = @company

    	if  @query.save
    		PullIndeedJob.perform_later(@query, @user, @company)
			redirect_to root_path, :notice => "Your job is executing!"
			return
		else
			redirect_to root_path, :notice => "Could not execute job!"
			return
		end

	end


	private


	def query_params
      params.require(:query).permit(:source, :url)
	end




end
