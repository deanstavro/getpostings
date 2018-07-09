class GetHunterContactsJob < ApplicationJob
    queue_as :default
  
    require 'open-uri'
    require 'json'
    require 'csv'
    require 'rest-client'


    def perform(domain_hash, user, company)
    
        puts "Starting Hunter Job"

        cleaned_domains = cleanDomains(domain_hash)
        puts cleaned_domains

        for domain in cleaned_domains
            hunter_apis = getHunterContacts(domain_hash)
            puts hunter_apis

            for hunter in hunter_apis
            
                response = RestClient::Request.execute(
                method: :get, url: hunter
                )
                puts "HERE IS THE RESPONSE"
                puts response.code
                puts response.body
            end
        end
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
      key = "&api_key=81ce4e6a2bb11717dc61df607bbb7a0c6f7c82ae"
      hunter_domains = []
      for domain in domains
          hunter_domains << base_url+domain+key
      end

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