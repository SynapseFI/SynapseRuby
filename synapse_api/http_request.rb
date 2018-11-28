require 'rest-client'
require 'open-uri'
require 'json'
require_relative './error'

module SynapsePayRest
	# Wrapper for HTTP requests using RestClient.
	class HTTPClient

		# @!attribute [rw] base_url
		#   @return [String] the base url of the API (production or sandbox)
		# @!attribute [rw] config
		#   @return [Hash] various settings related to request headers
		attr_accessor :base_url, :config

		# @param base_url [String] the base url of the API (production or sandbox)
    	# @param client_id [String]
    	# @param client_secret [String]
    	# @param fingerprint [String]
    	# @param ip_address [String]
    	# @param logging [Boolean] (optional) logs to stdout when true
    	# @param log_to [String] (optional) file path to log to file (logging must be true)
		def initialize(base_url:, client_id:, client_secret:, fingerprint:, ip_address:, **options)

			log_to         = options[:log_to] || 'stdout'
			RestClient.log = log_to if options[:logging]
			@logging       = options[:logging]

			@config = {
				client_id: client_id,
				client_secret: client_secret,
				fingerprint: fingerprint,
				ip_address: ip_address,
				oauth_key:  '',
			}
			@base_url = base_url
		end

		# Returns headers for HTTP requests.
	    # 
	    # @return [Hash]
		def headers
			user    = "#{config[:oauth_key]}|#{config[:fingerprint]}"
			gateway = "#{config[:client_id]}|#{config[:client_secret]}"
			headers = {
				content_type: :json,
				accept: :json,
				'X-SP-GATEWAY' => gateway,
			    'X-SP-USER'    => user,
			    'X-SP-USER-IP' => config[:ip_address]
			}
		end

		# Alias for headers (copy of current headers)
		alias_method :get_headers, :headers 

		# update headers and return nothing
		def update_headers(oauth_key: nil, fingerprint: nil, client_id: nil, client_secret: nil, ip_address: nil, **options)
			config[:fingerprint]   = fingerprint if fingerprint
			config[:oauth_key]     = oauth_key if oauth_key
			config[:client_id]     = client_id if client_id
			config[:client_secret] = client_secret if client_secret
			config[:ip_address]    = ip_address if ip_address
			nil
		end

		# Send a POST request to the given path with the given payload
		# @param path [String] 
		# @param payload [HASH]
		# @param **options payload = idempotency_key [String] (optional) avoid accidentally performing the same operation twice
	    # @return [JSON] API response

	    #todo : add error handling
	    # @raise [SynapsePayRest::Error] subclass depends on HTTP response

	    def post(path, payload, **options) 
	    	#copy of current headers 
	    	headers = get_headers

	    	# update the headers with idempotency_key
	    	if options[:idempotency_key]
	    		headers = headers.merge({'X-SP-IDEMPOTENCY-KEY' => options[:idempotency_key]})
	    	end

	    	response = with_error_handling { RestClient::Request.execute(:method => :post, :url => full_url(path), :payload => payload.to_json, :headers => headers, :timeout => 300) }
	    	puts 'RESPONSE:', JSON.parse(response) if @logging
	    	response = JSON.parse(response) 
      	end

    # Sends a GET request to the given path with the given payload.
		# @param path [String]
		# @return [Hash] API response
		
		# @raise [SynapsePayRest::Error] subclass depends on HTTP response
		def get(path)
			response = with_error_handling {RestClient.get(full_url(path), headers)} 
			puts 'RESPONSE:', JSON.parse(response) if @logging
			JSON.parse(response)
		end

    def delete(path)
      response = with_error_handling {RestClient.delete(full_url(path), headers)} 
      puts 'RESPONSE:', JSON.parse(response) if @logging
      JSON.parse(response)
    end

		# Sends a PATCH request to the given path with the given payload.
	    # 
	    # @param path [String]
	    # @param payload [Hash]
	    # 
	    # @raise [SynapsePayRest::Error] subclass depends on HTTP response
	    # 
	    # @return [Hash] API response

	    # todo : add error 
		# @raise [SynapsePayRest::Error] subclass depends on HTTP response
		def patch(path, payload)
			response = with_error_handling {RestClient::Request.execute(:method => :patch, :url => full_url(path), :payload => payload.to_json, :headers => headers, :timeout => 300)} 
			p 'RESPONSE:', JSON.parse(response) if @logging
			JSON.parse(response)
		end

		private

		def full_url(path)
		  "#{base_url}#{path}"
		end

		def with_error_handling
			yield
		rescue RestClient::Exceptions::Timeout
			body = {
				error: {
					en: "Request Timeout"
				},
				http_code: 504
			}
			raise Error.from_response(body)
		rescue RestClient::Exception => e
			if e.response.headers[:content_type] == 'application/json' 
				body = JSON.parse(e.response.body)
			else
				body = {
					error: {
						en: e.response.body
					},
					http_code: e.response.code
				}
			end
			raise Error.from_response(body)
		end
	end
end


