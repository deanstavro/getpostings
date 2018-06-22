class PullIndeedJob < ApplicationJob
	queue_as :default
  require 'open-uri'
  require 'nokogiri'
  require 'json'
  require "csv"

	def perform(query, user, company)
    
    puts "Starting PullIndeed Job"

    total_limit = 950
    limit = 50
    url = query.url
    html = open(url)
    doc = Nokogiri::HTML(html)

    #Get number of companies
    counter = getIndeedCount(doc)
    puts "Total number of companies: " + counter.to_s

    # Limit number of companies to 1000
    count = limitCount(counter,total_limit, limit)
    puts "Number of companies we will pull based on indeed limits: " + count.to_s

    bridges = []
    # Loop through all pages, with the limit being 50, and the start being n
    (0..count).step(limit) do |n|
      url = query.url
      
      url = getUrl(url, limit, n)
      puts "URL"
      puts url.to_s

      html = open(url)
      doc = Nokogiri::HTML(html)

      
      company_info_list = getIndeedCompany(doc)

      #puts len(company_info_list).to_s
      
      company_info_list.each do |company|



        begin
          #Get Company Name
          company_name = getIndeedCompanyName(company)
          puts company_name

          bridges.push(
            company_name.to_s
            )

        rescue
          puts "CANT FIND"
        end




        puts "----------------------------------------------------"
      end

      puts "---------------- THIS IS ANOTHER RECORD ----------------------"

      sleep 5
    end

    CSV.open("file.csv", "wb") do |csv|
        csv << ["Company"]

        bridges.each do |bridge|
          csv << [bridge]
        end

        #uploader = ScrapeUploader.new
        #uploader.store!(csv)
    end

    

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









end