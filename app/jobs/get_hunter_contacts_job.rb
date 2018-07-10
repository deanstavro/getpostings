class GetHunterContactsJob < ApplicationJob
    queue_as :default
    include SpreadsheetHelp
    include Aws
  
    require 'open-uri'
    require 'json'
    require 'csv'
    require 'rest-client'


    def perform(file, query, domain_hash, user)
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

            bridges = []

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
                puts json_response.to_s

                domain =  json_response["data"]["domain"]
                organization = json_response["data"]["organization"]

                email_hash = json_response["data"]["emails"]


                #{"value"=>"hernandez.l@mcs4kids.com", "type"=>"personal", "confidence"=>94, 
                #"sources"=>[{"domain"=>"marktwain.mcs4kids.com", "uri"=>"http://marktwain.mcs4kids.com/staff/office-staff", "extracted_on"=>"2015-11-20", "last_seen_on"=>"2018-06-07", "still_on_page"=>true}],
                #{}"first_name"=>"Lupe", "last_name"=>"Hernandez", "position"=>"Administrative", "seniority"=>nil,
                #{}"department"=>"Management", "linkedin"=>nil, "twitter"=>nil, "phone_number"=>nil}

                for email_data in email_hash

                    begin
                        email_type = email_data["type"]
                    rescue 
                        email_type = ""
                    end


                    begin
                        email = email_data["value"]
                    rescue 
                        email = ""
                    end


                    begin
                        email_confidence = email_data["confidence"]
                    rescue 
                        email_confidence = ""
                    end


                    begin
                        first_name = email_data["first_name"]
                    rescue 
                        first_name = ""
                    end


                    begin
                        last_name = email_data["last_name"]
                    rescue 
                        last_name = ""
                    end


                    begin
                        position = email_data["position"]
                    rescue 
                        position = ""
                    end


                    begin
                        seniority = email_data["seniority"]
                    rescue 
                        seniority = ""
                    end


                    begin
                        department = email_data["department"]
                    rescue 
                        department = ""
                    end


                    begin
                        linkedin= email_data["linkedin"]
                    rescue 
                        linkedin = ""
                    end


                    begin
                        twitter = email_data["twitter"]
                    rescue 
                        twitter = ""
                    end


                    begin
                        phone_number = email_data["phone_number"]
                    rescue 
                        phone_number = ""
                    end

                    bridges.push(
                      [email, email_type, email_confidence, first_name,last_name, position, seniority, department, linkedin, twitter, phone_number]
                      )
                    
                end

            end


            worksheet_name = "Contacts"
            headers = ["email", "email type", "email confidence", "first name", "last name", "position", "seniority", "department", "linkedin", "twitter", "phone number"]
                
            book = populateOneSpreadsheet(worksheet_name,headers,bridges)

            directory_name = "tmp/csv"
            file_name = "find_contact.xls"

            path_to_file= File.join(Rails.root, directory_name, file_name)
            writeSpreadsheetToFile(directory_name, book, path_to_file)


            file_name_aws = "contact_download/contacts" + query.id.to_s + ".csv"
            puts "FILE NAME: " + file_name_aws

            begin
                bucket_name = "getpostings"

                object_url = uploadToAws(bucket_name, file_name_aws, path_to_file.to_s)
                query.update_attribute(:download_file, object_url)
            rescue
                puts "COULD NOT UPLOAD INTO AWS"
            end
            # Delete the file after is has been uploaded
            File.delete(path_to_file) if File.exist?(path_to_file)

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