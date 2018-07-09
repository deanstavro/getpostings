class FindContactsController < ApplicationController
  before_action :authenticate_user!
  include SpreadsheetHelp
  include Aws
	require 'csv'


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

    	begin
        	if (params[:find_contact][:csv_file].content_type).to_s == 'text/csv'
          		if (params[:find_contact][:csv_file].size).to_i < 1000000

                  file_path = params[:find_contact][:csv_file].path
                  domain_hash = []
                  CSV.foreach(file_path, headers: true) do |row|
                      puts "looping through each row"

                      #Take row, convert keys to lowercase, put in key,value hash
                      new_hash = {}

                      row.to_hash.each_pair do |k,v|

                          new_hash.merge!({k.downcase => v})

                          if new_hash["domain"].present?
                              domain_hash << new_hash["domain"]
                          end
                      end 
                  end

                  begin
                      if domain_hash.count > 0 
                          puts domain_hash
                          #save object_url, department, and seniority
                          @query = FindContact.new(query_params)
                          @query.client_company = @company

                          if  @query.save

                              # Call hunter job
                              GetHunterContactsJob.perform_later(file_path, @query, domain_hash, @user, @company)

                              redirect_to find_contacts_path, :flash => { :notice => "File Uploaded. Job has started!" }
                              return
                          else
                              redirect_to new_find_contact_path, :flash => { :error => "Error! Could not save the current query!" }
                              return
                          end
                      else
                          redirect_to new_find_contact_path, :flash => { :error => "Error! Could not find any domains in the 'domain' header!" }
                          return
                      end

                  rescue
                      redirect_to new_find_contact_path, :flash => { :error => "Error! Could not Pull Contacts" }
                      return
                  end

          		else
          			  redirect_to new_find_contact_path, :flash => { :error => "The file is to large. Please Upload a shorter CSV!" }
          			  return
          		end
          else
          		redirect_to new_find_contact_path, :flash => { :error => "Error! Upload a CSV!" }
          		return
          end
    	rescue
        	redirect_to new_find_contact_path, :flash => { :error => "Error!" }
        	return
      end

	end




	private


	def query_params
      params.require(:find_contact).permit(:csv_file, :seniority, :department)
	end

	def checkHasDomain(csv_file)
		puts "WE HERE"
		
		CSV.foreach(csv_file, :headers => true) do |row|
  			puts row.to_s
		end

		return true

	end



end
