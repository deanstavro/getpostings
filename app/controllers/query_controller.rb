class QueryController < ApplicationController
	before_action :authenticate_user!
	#include Wicked::Wizard

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

    		if @query.source == "indeed"
	    		indeed_link = getIndeedLink(@query)
	    		@query.update_attribute(:url, indeed_link)
	    		aws_link = PullIndeedJob.perform_later(@query, @user, @company)
	    	else
	    		yellow_pages_link = getYellowPagesLink(@query)
	    		@query.update_attribute(:url, yellow_pages_link)
	    		aws_link = PullYellowPagesJob.perform_later(@query, @user, @company)
	    	end
    		
			redirect_to root_path, :notice => "Your job is executing!"
			return
		else
			redirect_to root_path, :notice => "Could not execute job!"
			return
		end

	end


	private


	def query_params
      params.require(:query).permit(:source, :url, :keywords, :location)
	end

	def getIndeedLink(query)
		base_url = "https://www.indeed.com/jobs?q="

		key = query.keywords.gsub(' ','+')
		location = query.location.gsub(' ','+')

		return base_url+key+"&l="+location
	end

	def getYellowPagesLink(query)
		base_url = "http://www.yellowpages.com/search?search_terms="

		key = query.keywords.gsub(' ','+').gsub(',','')
		location = query.location.gsub(' ','+').gsub(',','')

		return base_url+key+"&geo_location_terms="+location
	end



end
