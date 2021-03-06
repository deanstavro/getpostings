class FindCompaniesController < ApplicationController
	before_action :authenticate_user!
	#include Wicked::Wizard

	def index
		@user = User.find(current_user.id)
    	# grab reports and grab leads for every week for a report
    	@queries = FindCompany.where(user_id: @user.id).order('updated_at DESC').paginate(:page => params[:page], :per_page => 20)
	end


	def new
		@query = FindCompany.new
	end


	def create
		@user = User.find(current_user.id)

    	@query = FindCompany.new(query_params)
    	@query.user = @user

    	if  @query.save

    		if @query.source == "search by job postings"
	    		indeed_link = getIndeedLink(@query)
	    		@query.update_attribute(:url, indeed_link)
	    		aws_link = PullIndeedJob.perform_later(@query, @user)
	    	else
	    		yellow_pages_link = getYellowPagesLink(@query)
	    		@query.update_attribute(:url, yellow_pages_link)
	    		aws_link = PullYellowPagesJob.perform_later(@query, @user)
	    	end
    		
			redirect_to find_companies_path, :notice => "Your job is executing!"
			return
		else
			redirect_to find_companies_path, :notice => "Could not execute job!"
			return
		end

	end


	private


	def query_params
      params.require(:find_company).permit(:source, :url, :keywords, :location)
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
