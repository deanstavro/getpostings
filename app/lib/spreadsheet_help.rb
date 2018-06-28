
require 'json'
require 'csv'
require 'spreadsheet'

module SpreadsheetHelp

	# Returns spreadsheet with one sheet, containing the sheet name, headers, and content
  	def populateOneSpreadsheet(worksheet_name,headers,bridges)

        Spreadsheet.client_encoding = 'UTF-8'
        book = Spreadsheet::Workbook.new

        sheet1 = book.create_worksheet(:name => worksheet_name)

        sheet1.row(0).concat headers

        row_number = 1

        bridges.each do |bridge|
            sheet1.row(row_number).concat(bridge)
            row_number = row_number+1
        end

        return book
    end



    #saves a spreadsheet to a local folder
    def  writeSpreadsheetToFile(directory_name, book, path_to_file)
        puts "writing spreadsheet to file"
        Dir.mkdir(directory_name) unless File.exists?(directory_name)
        book.write path_to_file

        sleep 5
	end

    class Upload
        mount_uploader :file, FileUploader
    end






end