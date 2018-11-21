require_relative './http_request'
require 'mime-types'
require 'base64'
require 'open-uri'
require 'json'
require_relative './node'
require_relative './nodes'
require_relative './transaction'
require_relative './transactions'

module SynapsePayRest

	class User

		# Valid optional args for #get
   		# @todo Should refactor this to HTTPClient
    	VALID_QUERY_PARAMS = [:query, :page, :per_page, :full_dehydrate].freeze

    	attr_reader :client
		attr_accessor :user_id,:refresh_token, :base_documents, :oauth_key, :expires_in, :flag, :ips, :payload, :document_id, :full_dehydrate

		def initialize(user_id:,refresh_token:, client:,payload:, full_dehydrate:)
			@user_id = user_id
			@client = client
			@refresh_token = refresh_token
			@user_id = user_id
			@payload =payload
			@full_dehydrate =full_dehydrate
		end

		# make sure address is correcrt else method will raise an error 
		def add_base_doc(documents:)
			path = get_user_path(user_id:self.user_id)
			client.patch(path,documents)
			nil
		end

		# adding to base doc after base doc is created 
		# developer passes full payload 
		def update_base_doc(documents)
			path = get_user_path(user_id: self.user_id)
			client.patch(path, documents)
			nil 
		end

		
		def get_all_nodes(**options)
			[options[:page], options[:per_page]].each do |arg|
				if arg && (!arg.is_a?(Integer) || arg < 1)
					raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
				end
			end
			path = nodes_path(options: options)
			nodes = client.get(path)
			return [] if nodes["nodes"].empty?
			response = nodes["nodes"].map { |node_data| Node.new(node_id: node_data['_id'], user_id: node_data['user_id'], http_client: client, payload: node_data, full_dehydrate: "no")}
			nodes = Nodes.new(limit: nodes["limit"], page: nodes["page"], page_count: nodes["page_count"], node_count: nodes["node_count"], payload: response, http_client: client)
		end

		def refresh_token(**options)
			path = get_user_path(user_id: self.user_id, options: options)
			response = client.get(path)
			refresh_token = response["refresh_token"]
			refresh_token
		end

		# options params: payload to change scope 
		def authenticate(**options)
			payload = payload_for_refresh(refresh_token: self.refresh_token)
			path = oauth_path(options: options)
			oauth_response = client.post(path, payload)
			oauth_key = oauth_response['oauth_key']
			oauth_expires = oauth_response['expires_in']
			self.oauth_key = oauth_key
			self.expires_in = oauth_expires
			# self.expire = 0 
			# seld. authenticate 
			client.update_headers(oauth_key: oauth_key)
			self 
		end

		def info
			user = {:id => self.user_id, :full_dehydrate => self.full_dehydrate, :payload => self.payload}
			JSON.pretty_generate(user)
		end

		def delete_user
			path = get_user_path(user_id: self.user_id)
			documents = { "permission": "MAKE-IT-GO-AWAY" }
			client.patch(path, documents)
			nil 
		end

		  # Queries the API for all transactions belonging to a user and returns
	      # them as Transactions instances.
	      # 
	      # @param user_id 
	      # @param options[:page] [String,Integer] (optional) response will default to 1
	      # @param options[:per_page} [String,Integer] (optional) response will default to 20
	    def get_transactions(**options)

			[options[:page], options[:per_page]].each do |arg|
				if arg && (!arg.is_a?(Integer) || arg < 1)
					raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
				end
			end

	      	refresh_token = refresh_token(user_id: self.user_id)
	      	oauth_path = oauth_path(self.user_id)
	      	authenticate(refresh_token,oauth_path)
	      	path = transactions_path(user_id: self.user_id, options: options)
	      	trans = client.get(path)
	      	response = trans["trans"].map { |trans_data| Transaction.new(trans_id: trans_data['_id'], http_client: client, payload: trans_data)}
	      	trans = Transactions.new(limit: trans["limit"], page: trans["page"], page_count: trans["page_count"], trans_count: trans["trans_count"], payload: response, http_client: client)
	      	trans
	    end


		def create_node(payload:)
			path = get_user_path(user_id: self.user_id)
			path = path + nodes_path
			response = client.post(path,payload)
			
			node = Node.new(
				user_id: self.user_id,
				node_id: response["nodes"][0]["_id"],
				full_dehydrate: "no",
				http_client: client, 
				payload: response
				)
			node
		end


		private

		def oauth_path(**options)
			path = "/oauth/#{user_id}"
		end

		def payload_for_refresh(refresh_token:)
			{'refresh_token' => refresh_token}
		end

		def get_user_path(user_id:, **options)
			path = "/users/#{user_id}"
			params = VALID_QUERY_PARAMS.map do |p|
				options[p] ? "#{p}=#{options[p]}" : nil
			end.compact
			path += '?' + params.join('&') if params.any?
			path 
		end

		def nodes_path(**options)
			path = "/nodes"
			params = VALID_QUERY_PARAMS.map do |p|
				options[p] ? "#{p}=#{options[p]}" : nil
			end.compact

			path += '?' + params.join('&') if params.any?
			path
		end

	end
end


#def from_response(response, options = "no", oauth: true)
       # user = User.new(
        #  user_id:                response['_id'],
        #  refresh_token:     response['refresh_token'],
        #  client:            client,
        #  full_dehydrate:    options,
        #  payload:           response
        #)

        #if response.has_key?('flag')
          #user.flag = response['flag']
        #end

        #if response.has_key?('ips')
          #user.ips = response['ips']
        #end

        # add base doc validation 
        # add oauth criteria

        # return is a user object 
        # turning the object to a json 

        # automates authentication upon creating a user  
        # call the authenticate method is  oauth expires 
        #oauth ? user.authenticate : user
      #end

      # to-do create a user from user data
      #def multiple_from_response(response)
      #return [] if response.empty?
      #response.map { |user_data| from_response(user_data, oauth: false)}
      #end


