class PullIndeedJob < ApplicationJob
	queue_as :default
  

  require 'open-uri'
  require 'nokogiri'
  require 'json'
  require 'csv'

  include Nokogiri

	

  def perform(query, user, company)
    
    puts "Starting Pull Indeed Job"

    base_url = "https://www.indeed.com"
    total_limit = 950
    limit = 50
    url = query.url
    doc = getNokogiriPage(url)

    #Get number of companies
    counter = getIndeedCount(doc)
    puts "Total number of companies: " + counter.to_s

    # Limit number of companies to 1000
    count = limitCount(counter,total_limit, limit)
    puts "Number of companies we will pull based on indeed limits: " + count.to_s

    bridges = []
    # Loop through all pages, with the limit being 50, and the start being n
    (0..count).step(limit) do |n|
      # Reset Url
      url = query.url
      
      url = getUrl(url, limit, n)
      puts "URL"
      puts url.to_s

      doc = getNokogiriPage(url)

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
            job_opening_page_scrape = getNokogiriPage(indeed_company_link)

            if job_opening_page_scrape != nil
              company_domain = getDomain(job_opening_page_scrape)
            else
              company_domain = ""
            end
          else

            company_domain = ""
          end

          # Get summary
          

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

      puts "---------------- THIS IS ANOTHER RECORD ----------------------"

      sleep 5
    end



    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    
    populateSpreadsheet(book, bridges)

    
    directory_name = "tmp/csv"
    Dir.mkdir(directory_name) unless File.exists?(directory_name)
    
    path_to_file = File.join(Rails.root, 'tmp/csv', "data.xls")
    book.write path_to_file

    sleep 15

    if url.include?"https://www.indeed.com/jobs?"
      url.delete!('https://www.indeed.com/jobs?') 
    end

    query_id= query.id
    file_name_aws = query.id.to_s + "_" + user.first_name + "_" + url + ".csv"
    puts "FILE NAME"
    puts file_name_aws

    begin

      # Get AWS credentials and connect to s3
      s3 = Aws::S3::Resource.new(credentials: Aws::Credentials.new('AKIAI3YSAR6H2RJ4YJMA', 'aB11Vdv5nWKXVuG7cJYMdfVypjTOj1f//xtwbsff'),region: 'us-west-1')
      puts "UNO"
      #create object with bucket choose bucket
      obj = s3.bucket('getpostings').object(file_name_aws)
      obj.upload_file(path_to_file, acl:'public-read')
      puts "DOS"
      # Delete the file after is has been uploaded
      File.delete(path_to_file) if File.exist?(path_to_file)
      puts "TRES"

      aws_url = obj.public_url.to_s
      query.update_attribute(:file_download, aws_url)
      
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


  def populateSpreadsheet(book, bridges)
    sheet1 = book.create_worksheet(:name => 'Campaign')
    sheet2 = book.create_worksheet(:name => 'Contacts')

    sheet1.row(0).concat ["Company","Job Title", "City/State", "Open Position Summary", "Company Domain", "Indeed Company Page"]

    row_number = 1

    bridges.each do |bridge|
      sheet1.row(row_number).concat(bridge)
      row_number = row_number+1
    end
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



  def getNokogiriPage(link)
    html = open(link)
    doc = Nokogiri::HTML(html)
    sleep 1
    return doc
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


          #puts l[0]
          #return l[0].to_s
        rescue
          return ""
        end
        
        
    rescue
      return ""
    end
  end


end