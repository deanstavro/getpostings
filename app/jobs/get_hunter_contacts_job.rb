class GetHunterContactsJob < ApplicationJob
    queue_as :default
    include SpreadsheetHelp
    include Aws
  
    require 'open-uri'
    require 'json'
    require 'csv'
    require 'rest-client'


    def perform(file, query, domain_hash, user, company)
        puts "Starting Hunter Job"


        #### SAVE FILE TO AWS ######
        bucket_name = "getpostings"
        file_name = "find_contacts/contacts_" + query.id.to_s + ".csv"

        object_url = uploadToAws(bucket_name, file_name, file)

        #### UPDATE QUERY WITH AWS LINK ####
        query.update_attribute(:csv_file, object_url.to_s) 
        puts "uploaded file saved, query updated with file link"

        cleaned_domains = cleanDomains(domain_hash)
        puts cleaned_domains

        for domain in cleaned_domains
            hunter_apis = getHunterContacts(query, domain_hash)
            puts hunter_apis

            csv_rows_hash = {}

            for hunter in hunter_apis
            
                response = RestClient::Request.execute(
                method: :get, url: hunter
                )
                puts "HERE IS THE RESPONSE"
                
                if response.code != 200
                  query.update_attribute(:download_file, "Contact ScaleRep - could not pull data")
                  return
                end

                # Add Data into hash
                json_response = JSON.parse(response.body.to_s)

                domain =  json_response["data"]["domain"]
                organization = json_response["data"]["organization"]

                email_hash = json_response["data"]["emails"]

                for email in email_hash
                  puts email.to_s
                end

            end

            # Create Spreadsheet and add headers and hash

            # Upload file to AWS

            # Update download_file so that the url is reflected
        end
    end




  private



  def getNokogiriPage(link)
      html = open(link)
      doc = Nokogiri::HTML(html)
      sleep 1
      return doc
  end


  def getHunterContacts(query, domains)
      base_url = "https://api.hunter.io/v2/domain-search?domain="
      key = "&api_key=81ce4e6a2bb11717dc61df607bbb7a0c6f7c82ae"

      if query.seniority.present?
          seniority = "&seniority="+query.seniority
      else
          seniority = ""
      end

      puts "SENIORITY: " + seniority

      if query.department.present?
          department = "&department="+query.department
      else
          department = ""
      end

      puts "DEPARTMENT: " + department 

      hunter_domains = []
      for domain in domains
          hunter_domains << base_url+domain+seniority+department+key
      end
      puts hunter_domains

      return hunter_domains
  end


  def cleanDomains(domains)
      cleaned_domains = []
      for domain in domains
          domain = domain.gsub("https://", "")
          domain = domain.gsub("http://", "")
          cleaned_domains << domain
      end

      return cleaned_domains
  end




end