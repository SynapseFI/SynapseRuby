require_relative './http_request'
require 'mime-types'
require 'base64'
require 'open-uri'
require 'json'
require_relative './error'
require_relative './node'
require_relative './nodes'
require_relative './transaction'
require_relative './transactions'

module SynapsePayRest

	class User

		# Valid optional args for #get
    VALID_QUERY_PARAMS = [:query, :page, :per_page, :full_dehydrate, :ship, :force_refresh].freeze

    attr_reader :client
		attr_accessor :user_id,:refresh_token, :oauth_key, :expires_in, :payload, :full_dehydrate

		def initialize(user_id:,refresh_token:, client:,payload:, full_dehydrate:)
			@user_id = user_id
			@client = client
			@refresh_token = refresh_token
			@payload =payload
			@full_dehydrate =full_dehydrate
		end

		# adding to base doc after base doc is created 
		# pass in full payload 
		# function used to make a base doc go away and update sub-doc
		# see https://docs.synapsefi.com/docs/updating-existing-document
		def user_update(payload:)
			path = get_user_path(user_id: self.user_id)
     begin
       response = client.patch(path, payload)
     rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response =client.patch(path, documents)
     end
			response
		end

	    # Queries Synapse API for all nodes belonging to user (with optional
      # filters) and returns them as node instances.
      # @param page [String,Integer] (optional) response will default to 1
      # @param per_page [String,Integer] (optional) response will default to 20
      # @param type [String] (optional)
	    # @see https://docs.synapsepay.com/docs/node-resources node types
	    # @return [Array<SynapsePayRest::Nodes>] 
		def get_all_nodes(**options)
			[options[:page], options[:per_page]].each do |arg|
				if arg && (!arg.is_a?(Integer) || arg < 1)
					raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
				end
			end
			path = nodes_path(options: options)
      begin
       nodes = client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       nodes = client.get(path)
      end

			return [] if nodes["nodes"].empty?
			response = nodes["nodes"].map { |node_data| Node.new(node_id: node_data['_id'], user_id: node_data['user_id'], http_client: client, payload: node_data, full_dehydrate: "no")}
			nodes = Nodes.new(limit: nodes["limit"], page: nodes["page"], page_count: nodes["page_count"], node_count: nodes["node_count"], payload: response, http_client: client)
		end


		# Queries Synapse get user API for users refresh_token
    # @param full_dehydrate [Boolean] 
    # @see https://docs.synapsefi.com/docs/get-user
    # @return refresh_token string
		def refresh_token(**options)
			options[:full_dehydrate] = "yes" if options[:full_dehydrate] == true
			options[:full_dehydrate] = "no" if options[:full_dehydrate] == false

			path = get_user_path(user_id: self.user_id, full_dehydrate: options[:full_dehydrate])
			response = client.get(path)
			refresh_token = response["refresh_token"]
			refresh_token 
		end

		# Quaries Synapse get oauth API for user after extracting users refresh token
		# @params scope [Array<Strings>]
    # @see https://docs.synapsefi.com/docs/get-oauth_key-refresh-token 
		# Function does not support registering new fingerprint
		def authenticate(**options)
      payload = {
        "refresh_token" => self.refresh_token()
      }
      payload["scope"] = options[:scope] if options[:scope] 
      
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

		# Returns users information
		def info
			user = {:id => self.user_id, :full_dehydrate => self.full_dehydrate, :payload => self.payload}
			JSON.pretty_generate(user)
		end

	  # Queries the Synapse API get all user transactions belonging to a user and returns
    # them as Transactions instances [Array<SynapsePayRest::Transactions>] 
    # @param options[:page] [String,Integer] (optional) response will default to 1
    # @param options[:per_page} [String,Integer] (optional) response will default to 20
    def get_transactions(**options)
  		[options[:page], options[:per_page]].each do |arg|
  			if arg && (!arg.is_a?(Integer) || arg < 1)
  				raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
  			end
  		end

      path = transactions_path(user_id: self.user_id, options: options)

      begin
        trans = client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
        self.authenticate()
        trans = client.get(path)
      end

      
      response = trans["trans"].map { |trans_data| Transaction.new(trans_id: trans_data['_id'], payload: trans_data)}
      trans = Transactions.new(limit: trans["limit"], page: trans["page"], page_count: trans["page_count"], trans_count: trans["trans_count"], payload: response)

    	trans
    end

    def get_transaction(node_id:,trans_id:,**options)
      path = "/users/#{self.user_id}/nodes/#{node_id}/trans/#{trans_id}" 
      begin
        trans = client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
        self.authenticate()
        trans = client.get(path)
      end 
      transaction = Transaction.new(trans_id: trans['_id'], payload: trans)
      transaction
    end

    def cancel_transaction(node_id:,trans_id:,**options)
      path = "/users/#{self.user_id}/nodes/#{node_id}/trans/#{trans_id}" 
      begin
        response = client.delete(path)
      rescue SynapsePayRest::Error::Unauthorized
        self.authenticate()
        response = client.delete(path)
      end 
      response
    end

    def comment_transaction(node_id:,trans_id:, payload:,**options)
      path = "/users/#{self.user_id}/nodes/#{node_id}/trans/#{trans_id}" 
      begin
        trans = client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        self.authenticate()
        trans = client.patch(path, payload)
      end 
      transaction = Transaction.new(trans_id: trans['_id'], payload: trans)
      transaction
    end

      # Creates a card-us node in the API associated to the provided user and
      # returns a node instance from the response data
      # @param nickname [String]
      # @param type [String]
      # @see https://docs.synapsefi.com/docs/deposit-accounts for example
      # @return [SynapsePayRest::Node]
		def create_card_us_node(payload:)
			path = get_user_path(user_id: self.user_id)
			path = path + nodes_path
	
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

			
			node = Node.new(
				user_id: self.user_id,
				node_id: response["nodes"][0]["_id"],
				full_dehydrate: false,
				http_client: client, 
				payload: response
				)
			node
		end

    def ship_card(node_id: ,payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path + "/#{node_id}?ship=YES"
  
      begin
       response = client.patch(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.patch(path,payload)
      end
      response
    end

    def create_deposit_us(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response
        )
      node
    end

    def create_ach_us_logins(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response
        )
      node
    end

    def create_ach_us_act_rt(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response
        )
      node
    end

    def create_interchange_us(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response
        )
      node
    end

    def create_check_us(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response
        )
      node
    end

    def create_check_us(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response
        )
      node
    end

    def create_crypto_us(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response
        )
      node
    end

    def create_wire_us(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response
        )
      node
    end

    def create_wire_int(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response
        )
      node
    end

    def create_iou(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response
        )
      node
    end

    def create_ubo(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path + "/ubo"
  
      begin
       response = client.patch(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.patch(path,payload)
      end

      response
    end

		def get_node(node_id:, **options)
      options[:full_dehydrate] = "yes" if options[:full_dehydrate] == true
      options[:full_dehydrate] = "no" if options[:full_dehydrate] == false
      options[:force_refresh] = "yes" if options[:force_refresh] == true
      options[:force_refresh] = "no" if options[:force_refresh] == false

			path = node(node_id:node_id, full_dehydrate: options[:full_dehydrate],force_refresh: options[:force_refresh] )
      
			node = client.get(path)

      begin
       node = client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       node = client.get(path)
      end

	
			node = Node.new(node_id: node['_id'], 
				user_id: node['user_id'], 
				http_client: client, 
				payload: node, 
				full_dehydrate: options[:full_dehydrate] == "yes" ? true : false
				)
			node
		end

		private

		def oauth_path(**options)
			path = "/oauth/#{self.user_id}"
		end

		def get_user_path(user_id:, **options)
			path = "/users/#{user_id}"
			params = VALID_QUERY_PARAMS.map do |p|
				options[p] ? "#{p}=#{options[p]}" : nil
			end.compact
			path += '?' + params.join('&') if params.any?
			path 
		end

		def transactions_path(user_id:, **options)
			path = "/users/#{user_id}/trans" 
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

    def node(node_id:, **options)
      path = "/users/#{self.user_id}/nodes/#{node_id}"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact

      path += '?' + params.join('&') if params.any?

      path
    end
	end
end

