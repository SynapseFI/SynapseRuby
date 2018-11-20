require_relative './http_request'
require 'mime-types'
require 'base64'
require 'open-uri'
require 'json'
require_relative './node'
require_relative './nodes'

module SynapsePayRest

	class User

		# Valid optional args for #get
   		# @todo Should refactor this to HTTPClient
    	VALID_QUERY_PARAMS = [:query, :page, :per_page, :full_dehydrate].freeze

    	attr_reader :client
		attr_accessor :user_id,:refresh_token, :base_documents, :oauth_key, :expires_in, :flag, :ips, :payload, :document_id

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
			# grabs users payload in order to update documents
			payload = self.payload.to_json
			payload = JSON.parse(payload) 
			document_id  = payload["documents"][0]["id"]
			self.document_id = document_id 

			# update document payload with document id 
			documents[:documents][0]["id"] = self.document_id
			path = get_user_path(user_id: self.user_id)
			client.patch(path, documents)
			nil 
		end

		def delete_base_doc
			# grabs users payload in order to update documents
			payload = self.payload.to_json
			payload = JSON.parse(payload) 
			document_id  = payload["documents"][0]["id"]
			self.document_id = document_id 
			documents = {
				"documents":[{
					"id": self.document_id,
					"permission_scope":"DELETE_DOCUMENT"
				}]
			}
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


