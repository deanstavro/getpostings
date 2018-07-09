class FindContactsController < ApplicationController
  include SpreadsheetHelp
  include Aws
	before_action :authenticate_user!
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

		  puts "Starting importing for find contacts"
		  @user = User.find(current_user.id)
      @company = ClientCompany.find_by(id: @user.client_company_id)
      puts "Start Begin"
    	begin
        	if (params[:file].content_type).to_s == 'text/csv'
          		if (params[:file].size).to_i < 1000000

                domain_hash = []
                CSV.foreach(params[:file].path, headers: true) do |row|
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
                        GetHunterContactsJob.perform_later(domain_hash, @user, @company)

                        redirect_to find_contacts_path, :flash => { :notice => "File Uploaded. Job has started!" }
                        return
                    else
                        redirect_to new_find_contact_path, :flash => { :error => "Error! Could not find any domains in the 'domain' header!" }
                        return
                    end

                rescue
                    redirect_to new_find_contact_path, :flash => { :error => "Error! Could not Pull Contacts" }
                    return
                end





          			#if headers.include?('company domain') or headers.include? 'Company_domain' or headers.include? 'domain'

                #    directory_name = "tmp/csv"
                #    file_name = "contacts.xls"
                #    path_to_file= File.join(Rails.root, directory_name, file_name)

                #    writeSpreadsheetToFile(directory_name, csv_file, path_to_file)
          				
          			#	  GetHunterContactsJob.perform_later(csv_file, @user, @company)

          			#	  redirect_to find_contacts_path, :flash => { :notice => "File Uploaded. Job has started!" }
          			#	  return

          				

          			#else
          			#	redirect_to new_find_contact_path, :flash => { :error => "Error! Could not find 'company_domain' header in the CSV file!" }
          			#	return

          			# => end


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

    	#@query = FindContact.new(query_params)
    	#@query.client_company = @company

    	#if  @query.save
    		
		#	redirect_to find_contacts_path, :notice => "Your job is executing!"
		#	return
		#else
		#	redirect_to find_contacts_path, :notice => "Could not execute job!"
		#	return
		#end

	end


	private


	def query_params
      params.require(:find_contact).permit(:source, :url, :keywords, :location)
	end

	def checkHasDomain(csv_file)
		puts "WE HERE"
		
		CSV.foreach(csv_file, :headers => true) do |row|
  			puts row.to_s
		end

		return true

	end



end
