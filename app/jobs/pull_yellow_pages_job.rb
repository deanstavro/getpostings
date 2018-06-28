class PullYellowPagesJob < ApplicationJob
    include HtmlParser
    include SpreadsheetHelp
    include Aws
    queue_as :default
    

    require 'open-uri'
    require 'nokogiri'
    require 'json'
    require 'csv'

  

  


    def perform(query, user, company)

        puts "Starting Yellow Pages Job"
        limit = 30 #30 rows per page
        url = query.url
        html_doc = parseHtml(url)

    	  begin

            ###### If we can't determin total rows, we return and exit #####
    		    begin

  	  		      counter = getRowCount(html_doc)
                puts counter

  	  		      if counter.to_i == 0
                    puts "0 rows returned. This is an invalid query"
  	  			        return
  	  		      end
  	  	    rescue
                puts "Could not get total number of rows. This is an invalid query"
  	  		      return
  	  	    end

            ####### Determine the toal pages for a yellow page query #######
    		    total_pages = determineTotalPagesToScrape(counter.to_i, limit)
    		    puts "TOTAL Yellow Pages: " + total_pages.to_s

    		    bridges = []
    		    ######## Loop the total number of pages #############
    		    1.upto(total_pages) do |i|
          			
                original_url = query.url
          			to_concat = "&page="+i.to_s
          			new_url = original_url+to_concat
          			puts "NEW URL: " + new_url
                

          			html_doc = parseHtml(new_url)
          			company = getRowArray(html_doc)

                #### Loop through all the rows on the page for yellow page we're on #######
          			for row in company
                    #print the row
            				#puts row.to_s
            				
            				# Get Company Name
            				company_name = getCompanyName(row)
            				puts "COMPANY NAME: " + company_name.to_s
            				
                    # Get Company Number
            				phone_number = getPhoneNumber(row)
            				puts "PHONE NUMBER: " + phone_number
            				# Get Company Address
            				address = getAddress(row)
            				puts "ADRESS: " + address

            				# Get Industry
            				industry = getIndustry(row)
            				puts "INDUSTRY: " + industry

            				# Get Company Domain
            				company_domain = companyDomain(row)
            				puts "DOMAIN:" + company_domain

                    #Create array to push into a spreadsheet
            				bridges.push(
            					[company_name, phone_number, address, industry, company_domain]
                      	)

            				puts "-------------------------------------------"
          			end
    		    end

            worksheet_name = "Companies"
            headers = ["Company","Phone Number", "Address", "Industry", "Company Domain"]
            
        		book = populateOneSpreadsheet(worksheet_name,headers,bridges)

            directory_name = "tmp/csv"
            file_name = "yellow_pages.xls"


            path_to_file= File.join(Rails.root, directory_name, file_name)
            writeSpreadsheetToFile(directory_name, book, path_to_file)


        		file_name_aws = "yellow_pages/"+ query.id.to_s + "_" + query.location.to_s + "_" + query.keywords.to_s + ".csv"
        		puts "FILE NAME: " + file_name_aws

  		      begin
                bucket_name = "getpostings"

                object_url = uploadToAws(bucket_name, file_name_aws, path_to_file.to_s)
            	  query.update_attribute(:file_download, object_url)
      	    rescue
        	      puts "COULD NOT UPLOAD INTO AWS"
      	    end
      	    # Delete the file after is has been uploaded
            File.delete(path_to_file) if File.exist?(path_to_file)
    	  rescue
    		    puts "could not get total number of results"
    	  end

    end



    private


    def getRowCount(html_doc)
    	  puts "in Row Count"
    	  count_text =  html_doc.at_css("div.pagination").to_s
        counter = count_text.split('p>')[1].to_s
      
        full_sanitizer = Rails::Html::FullSanitizer.new
        text = full_sanitizer.sanitize(counter)

        return text.scan(/\d+/).first

    end



    def determineTotalPagesToScrape(results, limit)
      	if results < limit or results == limit
      		  return 1
      	elsif results % limit == 0
      		  return results/limit
      	else
      		  return results/limit + 1
      	end
    end



    def getRowArray(html_doc)
  	    company_docs = html_doc.xpath("//div[@class='info']")
  	    return company_docs
    end


    def getCompanyName(row)
      	count_text = row.at_css("a.business-name").to_s

      	full_sanitizer = Rails::Html::FullSanitizer.new
        text = full_sanitizer.sanitize(count_text).to_s
        text.sub! '&amp;', 'and'

      	return text
    end

    def getPhoneNumber(row)
      	count_text = row.at_css("div.phones").to_s

      	full_sanitizer = Rails::Html::FullSanitizer.new
        text = full_sanitizer.sanitize(count_text).to_s

      	return text
    end

    def getAddress(row)
      	count_text = row.at_css("p.adr").to_s

      	full_sanitizer = Rails::Html::FullSanitizer.new
        text = full_sanitizer.sanitize(count_text).to_s
        text.sub! '&amp;', 'and'
      	return text
    end


    def getIndustry(row)
      	count_text = row.at_css("div.categories").to_s

      	full_sanitizer = Rails::Html::FullSanitizer.new
        text = full_sanitizer.sanitize(count_text).to_s
        text.sub! '&amp;', 'and'
      	return text
    end

    def companyDomain(row)
    	  count_text = row.at_css("div.links").to_s

    	  if count_text.include? "href"
            company_link = count_text.split('href="')[1].split('"')[0].to_s
    		    return company_link
    	  else
    		    return ""
        end
    end

end