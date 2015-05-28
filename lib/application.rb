require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'

require 'json'
require 'yaml'

require_relative 'arguments'

#  ./bin/active_github.rb 2010-08-01 2015-05-09

module ActiveGithub
	class Application
		include Helpers

		def initialize(argv)
			@start_date, @end_date = validate_args(argv)
		end

		def run
			setup_google_api

			query = "SELECT TOP(repository_url, 10), COUNT(*)
				from [githubarchive:github.timeline] 
				where type = 'PushEvent'
				and PARSE_UTC_USEC(created_at) > PARSE_UTC_USEC('#{@start_date} 00:00:00')
				and PARSE_UTC_USEC(created_at) < PARSE_UTC_USEC('#{@end_date} 23:59:59');"

			result = query_google_api(query)

			parse_google_api_results(result) {|index,url,count| puts "#{index+1} url: #{url}, count: #{count}" }
		end		

		def setup_google_api
			opts = YAML.load_file("ga_config.yml")
			@project_id = opts['project_id']

			@client = Google::APIClient.new(
			  :application_name => 'ActiveGithub',
			  :application_version => '0.1.0',
			  :faraday_option => {timeout: 999}
			)

			key = Google::APIClient::KeyUtils.load_from_pkcs12(opts['key'],opts['key_secret'])

			@client.authorization = Signet::OAuth2::Client.new(
			  :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
			  :audience => 'https://accounts.google.com/o/oauth2/token',
			  :scope => 'https://www.googleapis.com/auth/bigquery.readonly',
			  :issuer => opts['service_email'],
			  :signing_key => key)

			@client.authorization.fetch_access_token!

			@bq = @client.discovered_api('bigquery', 'v2')
		end

		def query_google_api(query)
			puts "querying from #{@start_date} to #{@end_date}"
			@client.execute!(
			     :api_method => @bq.jobs.query,
			     :body_object => { "query" => query },
			     :parameters => { "projectId" => @project_id })
		end

		def parse_google_api_results(result, &block)
			rows = JSON.parse(JSON.dump(result.data["rows"]))
			rows.each_with_index do |r,index|
				f = r['f']
				url = f[0]['v']
				count = f[1]['v']
				yield index,url,count
			end
		end
	end
end