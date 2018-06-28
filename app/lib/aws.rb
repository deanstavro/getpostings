require 'csv'

module Aws

	###  Accepts a link, and returns an html_doc #####
  	def uploadToAws(bucket_name, file_name_aws, path_to_file)
  		puts "UPLOAD TO AWS"
		# Get AWS credentials and connect to s3
		s3 = Aws::S3::Resource.new(credentials: Aws::Credentials.new('AKIAI3YSAR6H2RJ4YJMA', 'aB11Vdv5nWKXVuG7cJYMdfVypjTOj1f//xtwbsff'),region: 'us-west-1')
		#create object with bucket choose bucket
		obj = s3.bucket(bucket_name).object(file_name_aws)
		obj.upload_file(path_to_file, acl:'public-read')
		sleep 5
		aws_url = obj.public_url.to_s
		return aws_url
 	 end




end