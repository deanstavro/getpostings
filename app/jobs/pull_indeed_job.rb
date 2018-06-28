class PullIndeedJob < ApplicationJob
    include HtmlParser
    include SpreadsheetHelp
    include Aws
    queue_as :default


    require 'open-uri'
    require 'nokogiri'
    require 'json'
    require 'csv'



    def perform(query, user, company)
      
        puts "Starting Pull Indeed Job"

        base_url = "https://www.indeed.com"
        total_limit = 950
        limit = 50
        url = query.url
        doc = parseHtml(url)

        #Get number of companies
        counter = getIndeedCount(doc)
        puts "Total number of companies: " + counter.to_s

        # Limit number of companies to 1000
        count = limitCount(counter,total_limit, limit)
        puts "Number of companies we will pull based on indeed limits: " + count.to_s

        bridges = []
        # Loop through all pages, with the limit being 50, and the start being n
        (0..count).step(limit) do |n|
            
            url = getUrl(query.url, limit, n)
            puts "URL: " + url.to_s

            doc = parseHtml(url)

            company_info_list = getIndeedCompany(doc)

            #Loop through every record on the page to grab contents
            company_info_list.each do |company|

                begin

                    #Get Company Name
                    company_name = getIndeedCompanyName(company)
                    # Get Open Position
                    job_title = getIndeedJobTitle(company)
                    # Get Location
                    location = getLocation(company)
                    # Get Summary
                    summary = getSummary(company)
                    # Get Summary link
                    
                    begin
                        indeed_company_link = getIndeedCompanyLink(base_url,company)
                    rescue
                        indeed_company_link = ""
                    end


                    if indeed_company_link != ""
                        # Get company about detail page if available 
                        job_opening_page_scrape = parseHtml(indeed_company_link)

                        if job_opening_page_scrape != nil
                            company_domain = getDomain(job_opening_page_scrape)
                        else
                            company_domain = ""
                        end
                    else
                        company_domain = ""
                    end

                    puts company_name
                    puts job_title
                    puts location
                    puts summary
                    puts company_domain
                    puts indeed_company_link
                    #puts summary

                    bridges.push(
                      [company_name,job_title, location, summary, company_domain, indeed_company_link]
                      )

                rescue
                    puts "CANT FIND"
                end

                puts "----------------------------------------------------"
            end

            puts "---------------- THIS IS ANOTHER PAGE ----------------------"

            sleep 2
        end

        worksheet_name = "Job Postings"
        headers = ["Company","Job Title", "City/State", "Open Position Summary", "Company Domain", "Indeed Company Page"]
            
        book = populateOneSpreadsheet(worksheet_name,headers,bridges)

        directory_name = "tmp/csv"
        file_name = "indeed.xls"

        path_to_file= File.join(Rails.root, directory_name, file_name)
        writeSpreadsheetToFile(directory_name, book, path_to_file)
        file_name_aws = "indeed/"+ query.id.to_s + "_" + query.location.to_s + "_" + query.keywords.to_s +"_jobpostings.csv"
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

    end



    private


    def getIndeedCompany(html_content)

        company_docs = html_content.xpath("//div[@class='  row  result']")
        return company_docs
    end


    def getIndeedCompanyName(company)

        begin
            count_text = company.css('.company').to_s
            
            text = count_text.split(">")

            if text[2]== nil
                company_name = text[1].split("<")[0]
            else
                company_name = text[2].split("<")[0]
            end

            company_name.sub! '&amp;', 'and'

            return company_name.to_s
        rescue

            return "NOT FOUND"

        end
    end


    def getIndeedCount(doc)
        count_text =  doc.at_css("div#searchCount").to_s
        counter = count_text.split('of')[-1].split(" ")[0].to_s

        if counter.include?","
            indeed_count = counter.delete!(',').to_i
        else
            indeed_count = counter.to_i
        end

        return indeed_count
    end


    def limitCount(indeed_count,total_limit, limit)
      if indeed_count < (total_limit + limit)
        count = indeed_count
      else
        count = total_limit
      end
      return count
    end


    def getUrl(url, limit, n)

        if url.include? "&limit=" #limit=<number>, change <number> to 50
            url.delete!('&limit=')
        end

        url = url +"&limit="+limit.to_s

        if url.include? "&start=" #if url contains start=<number>, change <number> to n
            url.delete!('&start=')
        end
        url = url +"&start="+n.to_s

        return url
    end


    def getIndeedJobTitle(company)

      begin
          count_text = company.css('.jobtitle').to_s
          position = count_text.split('title=')[1].split('"')[1].to_s

          position.sub! '&amp;', 'and'


          return position
      rescue

          return "NOT FOUND"

      end


    end


    def getLocation(company)

        begin
            count_text = company.css('.location').to_s
            location = count_text.split('>')[1].split('<')[0].to_s

            location.sub! '&amp;', 'and'

            return location
        rescue

            return "NOT FOUND"

        end
    end


    def getSummary(company)

      begin
          count_text = company.css('.summary').to_s

          full_sanitizer = Rails::Html::FullSanitizer.new
          text = full_sanitizer.sanitize(count_text)
          return text
      rescue

          return "NOT FOUND"

      end
    end


    def getIndeedCompanyLink(base_url, company)
        count_text = company.css('.company').to_s
      
        if count_text.include? "href"
            indeed_company_link = count_text.split('href="')[1].split('"')[0]
            cmpy_about_page = base_url + indeed_company_link+"/about"
            return cmpy_about_page
        else
            return ""
        end
    end


    def getDomain(job_opening_page_scrape)

        begin
              sidebar = job_opening_page_scrape.at_css("dl#cmp-company-details-sidebar")
              begin
                  sidebar.search('dt').each do |node|#.css('dt. a').map { |link| link['href'] }
                      if "#{node.text}" == "Links"
                          next_node = "#{node.next_element}".to_s
                          link = next_node.split('"')[1]
                          return link.to_s

                      end
                  end

                  return ""

              rescue
                  return ""
              end 
            
        rescue
            return ""
        end
    end


end