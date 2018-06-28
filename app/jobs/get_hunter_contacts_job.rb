class GetHunterContactsJob < ApplicationJob
    queue_as :default
  

    require 'open-uri'
    require 'nokogiri'
    require 'json'
    require 'csv'

	


    def perform(csv_file, user, company)
    
        puts "Starting Hunter Job"

        base_url = "https://www.indeed.com"
        total_limit = 950
        limit = 50

        domain_array = []
        CSV.foreach(csv_file, headers: true) do |row|

            #make row a dictionary
            row_dict = row.to_hash

            if row_dict["company_domain"].present?
                domain_array << row_dict["company_domain"]
            else
                puts "IT IS NOT PRESENT"
            end
          end

        domains = domain_array.uniq
        cleaned_domains = cleanDomains(domains)
        getHunterContacts(cleaned_domains)

	end



  private



  def getNokogiriPage(link)
      html = open(link)
      doc = Nokogiri::HTML(html)
      sleep 1
      return doc
  end


  def getHunterContacts(domains)
      base_url = "https://api.hunter.io/v2/domain-search?domain="

      for domain in domains
          puts base_url+domain
          #url = base_url+domain
      end
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