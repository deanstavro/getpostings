class PullYellowPagesJob < ApplicationJob
  queue_as :default
  require 'open-uri'
  require 'nokogiri'
  require 'json'
  require "csv"

  def perform(query, user, company)

  	puts "Starting Yellow Pages Job"
  	limit = 30 #30 rows per page
  	url = query.url
  	puts url
  	doc = getNokogiriPage(url)

  	begin

  		begin
	  		counter = getRowCount(doc)
	  		puts counter

	  		if counter.to_i == 0
	  			return
	  		end
	  	rescue
	  		return
	  	end


  		total_pages = determineTotalPagesToScrape(counter.to_i, limit)
  		puts "TOTAL Pages"
  		puts total_pages.to_s

  		bridges = []

  		# Loop the total number of pages
  		1.upto(total_pages) do |i|
  			url = query.url
  			to_concat = "&page="+i.to_s
  			new_url = url+to_concat
  			puts "NEW URL"
  			puts new_url
        sleep 2
  			doc = getNokogiriPage(new_url)

  			company = getRowArray(doc)


  			for row in company
  				puts row.to_s
  				
  				
  				# Get Company Name
  				company_name = getCompanyName(row)
  				
  				puts "COMPANY NAME"
  				puts company_name.to_s
  				# Get Company Number
  				phone_number = getPhoneNumber(row)
  				puts "PHONE NUMBER"
  				puts phone_number
  				# Get Company Address
  				address = getAddress(row)
  				puts "Address"
  				puts address

  				# Get Industry
  				industry = getIndustry(row)
  				puts "Industry"
  				puts industry

  				# Get Company Domain
  				company_domain = companyDomain(row)
  				puts "Domain"
  				puts company_domain


  				bridges.push(
  					[company_name, phone_number, address, industry, company_domain]
            	)


  				puts "-------------------------------------------"

  			end
  		end


  		Spreadsheet.client_encoding = 'UTF-8'
  		book = Spreadsheet::Workbook.new

  		populateSpreadsheet(book, bridges)


  		directory_name = "tmp/csv"
  		Dir.mkdir(directory_name) unless File.exists?(directory_name)

  		path_to_file = File.join(Rails.root, 'tmp/csv', "yellow_pages.xls")
  		book.write path_to_file

  		sleep 15

  		query_id = query.id
  		url = query.url
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

  	rescue
  		puts "could not get total number of results"
  	end

  end



  private



  def getNokogiriPage(link)
    html = open(link)
    doc = Nokogiri::HTML(html)
    sleep 1
    return doc
  end


  def getRowCount(doc)
  	puts "in Row Count"
  	count_text =  doc.at_css("div.pagination").to_s
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



  def getRowArray(doc)
  	company_docs = doc.xpath("//div[@class='info']")
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



  def populateSpreadsheet(book, bridges)
    sheet1 = book.create_worksheet(:name => 'Campaign')
    sheet2 = book.create_worksheet(:name => 'Contacts')

    sheet1.row(0).concat ["Company","Phone Number", "Address", "Industry", "Company Domain"]

    row_number = 1

    bridges.each do |bridge|
      sheet1.row(row_number).concat(bridge)
      row_number = row_number+1
    end
  end

end