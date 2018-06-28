module HtmlParser

	###  Accepts a link, and returns an html_doc #####
  	def parseHtml(link)
		html = open(link)
    	doc = Nokogiri::HTML(html)
    	sleep 2
    	return doc
 	 end




end