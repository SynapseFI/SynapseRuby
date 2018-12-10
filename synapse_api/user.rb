require_relative './http_request'
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
    VALID_QUERY_PARAMS = [:query, :page, :per_page, :type, :full_dehydrate, :ship, :force_refresh].freeze

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
			user = User.new(
            user_id:                response['_id'],
            refresh_token:     response['refresh_token'],
            client:            client,
            full_dehydrate:    false,
            payload:           response
          )
      user 
		end

	    # Queries Synapse API for all nodes belonging to user (with optional
      # filters) and returns them as node instances.
      # @param page [String,Integer] (optional) response will default to 1
      # @param per_page [String,Integer] (optional) response will default to 20
      # @param type [String] (optional)
	    # @see https://docs.synapsepay.com/docs/node-resources node types
	    # @return [Array<SynapsePayRest::Nodes>] 
		def get_all_user_nodes(**options)
			[options[:page], options[:per_page]].each do |arg|
				if arg && (!arg.is_a?(Integer) || arg < 1)
					raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
				end
			end
			path = get_user_path(user_id: self.user_id) + nodes_path(options)
    
      begin
       nodes = client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       nodes = client.get(path)
      end

			return [] if nodes["nodes"].empty?
			response = nodes["nodes"].map { |node_data| Node.new(node_id: node_data['_id'], user_id: node_data['user_id'], payload: node_data, full_dehydrate: "no")}
      nodes = Nodes.new(limit: nodes["limit"], page: nodes["page"], page_count: nodes["page_count"], nodes_count: nodes["node_count"], payload: response)
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
    def get_user_transactions(**options)
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

    # Creates Synapse node
    # returns a node instance from the response data
    # @param nickname [String]
    # @param type [String]
    # @see https://docs.synapsefi.com/docs/node-resources         
    # @return [SynapsePayRest::Node] or access token 
		def create_node(payload:)
			path = get_user_path(user_id: self.user_id)
			path = path + nodes_path
	
      begin
        response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
        self.authenticate()
        response = client.post(path,payload)
      end

      if response["nodes"]
        nodes = response["nodes"].map { |nodes_data| Node.new(user_id: self.user_id, node_id: nodes_data["_id"], full_dehydrate: false, payload: response)}
        nodes = Nodes.new(page: response["page"], limit: response["limit"], page_count: response["page_count"], nodes_count: response["node_count"], payload: nodes)
      else 
        #access_token = response["mfa"]
        access_token = response
      end

      access_token ? access_token : nodes 
		end

    # Submit answer to a MFA question using access token from bank login attempt
    # returns a node instance from the response data
    # @param payload
    # @see https://docs.synapsefi.com/docs/add-ach-us-node-via-bank-logins-mfa 
    # please be sure to call ach_mfa again if you have more security questions        
    def ach_mfa(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
        response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
        self.authenticate()
        response = client.post(path,payload)
      end

      if response["nodes"]
        nodes = response["nodes"].map { |nodes_data| Node.new(user_id: self.user_id, node_id: nodes_data["_id"], full_dehydrate: false, payload: response)}
        nodes = Nodes.new(page: response["page"], limit: response["limit"], page_count: response["page_count"], nodes_count: response["node_count"], payload: nodes)
      else 
        #access_token = response["mfa"]
        access_token = response
      end

      access_token ? access_token : nodes 
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


    # Queries the API for a node belonging to user(self),
    # and returns a node instance from the response data.
    # @param id [String] id of the node to find
    # @param full_dehydrate [String] (optional) if 'yes', returns all trans data on node
    # @param force_refresh [String] (optional) if 'yes', force refresh yes will attempt updating the account balance and transactions
		def get_user_node(node_id:, **options)
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
				user_id: self.user_id, 
				payload: node, 
				full_dehydrate: options[:full_dehydrate] == "yes" ? true : false,
				)
			node
		end

    # Gets statement by user.
    # @param page [SynapsePayRest::Client]
    # @param per_page [SynapsePayRest::User]  
    # @see https://docs.synapsefi.com/docs/statements-by-user
    def get_user_statement(**options)
      path = get_user_path(user_id: self.user_id) + "/statements"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact
      path += '?' + params.join('&') if params.any?
 
      statements = client.get(path)
      statements
    end

    def ship_card(node_id:, payload:)
    
      path = node(user_id: self.user_id, node_id: node_id) + "?ship=YES"
      
      begin
       response = client.patch(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       response = client.patch(path,payload)
      end
      response
    end

    def reset_debit_card(node_id:)
      path = node(user_id: self.user_id, node_id: node_id)  + "?reset=YES"
      payload = {}
      begin
       response = client.patch(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       response = client.patch(path,payload)
      end
      response
    end

    def create_transaction(node_id: ,payload:)
      path = trans_path(user_id: self.user_id, node_id: node_id)

      begin
       transaction = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       transaction = client.post(path,payload)
      end
      transaction = Transaction.new(trans_id: transaction['_id'], payload: transaction, node_id: node_id)
    end

    
    def get_node_transaction(node_id:, trans_id:)
      path = node(user_id: self.user_id, node_id: node_id) + "/trans/#{trans_id}" 
     
      begin
        trans = client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        trans = client.get(path)
      end 
      transaction = Transaction.new(trans_id: trans['_id'], payload: trans, node_id: node_id)
      transaction
    end

    def get_all_node_transaction(node_id:, **options)
      [options[:page], options[:per_page]].each do |arg|
        if arg && (!arg.is_a?(Integer) || arg < 1)
          raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
        end
      end

      path = node(user_id: self.user_id, node_id: node_id) + "/trans"

      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact

      path += '?' + params.join('&') if params.any?

      begin
        trans = client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        trans = client.get(path)
      end 

    
      response = trans["trans"].map { |trans_data| Transaction.new(trans_id: trans_data['_id'], payload: trans_data, node_id: node_id)}
      trans = Transactions.new(limit: trans["limit"], page: trans["page"], page_count: trans["page_count"], trans_count: trans["trans_count"], payload: response)
      trans
    end

    def verify_micro_deposit(node_id:,payload:)
      path = node(user_id: self.user_id, node_id: node_id)
      begin
        response = client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        response = client.patch(path, payload)
      end 
      response
    end


    def reinitiate_micro_deposit(node_id:)
      payload = {}
      path = node(user_id: self.user_id, node_id: node_id) + "?resend_micro=YES"
      begin
        response = client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        response = client.patch(path, payload)
      end 
      response
    end

    def generate_apple_pay_token(node_id:,payload:)
      path = node(user_id: self.user_id, node_id: node_id) + "/applepay"
      begin
        response = client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        response = client.patch(path, payload)
      end 
      response
    end

    def update_node(node_id:, payload:)
      path = node(user_id: self.user_id, node_id: node_id) 
     
      begin
        update = client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        update = client.patch(path, payload)
      end 
      update = Node.new(node_id: node_id, 
                        user_id: self.user_id, 
                        payload: update, 
                        full_dehydrate: false
                        )
    end

    def delete_node(node_id:)
      path = node(user_id: self.user_id, node_id: node_id) 
     
      if user == nil
        user = get_user(user_id: self.user_id)
      end

      begin
        delete = client.delete(path)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        delete = client.delete(path)
      end 
      delete
    end

    # Initiates dummy transactions to a node
    # @param is_credit [Boolean]
    def dummy_transactions(node_id:, is_credit: nil)

      is_credit = "YES" if is_credit == true
      is_credit = "NO" if is_credit == false
      if is_credit  
        path = node(user_id: self.user_id, node_id: node_id) + "/dummy-tran?#{is_credit}" 
      else
        path = node(user_id: self.user_id, node_id: node_id) + "/dummy-tran" 
      end

      begin
       response = client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       response = client.get(path)
      end
      response
    end

    # Creates subnet for a node 
    # @param [Hash] 
    def create_subnet(node_id:,payload:)
      path = subnet_path(user_id: self.user_id, node_id: node_id) 

      begin
       subnet = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       subnet = client.post(path,payload)
      end
      subnet = Subnet.new(subnet_id: subnet['_id'], payload: subnet, node_id: node_id)
      subnet
    end


    # Gets all node subnets.
    # @param page [Integer]
    # @param per_page [Integer]  
    # @see https://docs.synapsefi.com/docs/all-node-subnets
    def get_all_subnets(node_id:,**options)
      [options[:page], options[:per_page]].each do |arg|
        if arg && (!arg.is_a?(Integer) || arg < 1)
          raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
        end
      end

      path = node(user_id: self.user_id, node_id: node_id) + "/subnets"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact
      path += '?' + params.join('&') if params.any?

      begin
       subnets = client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       subnets = client.get(path)
      end

      response = subnets["subnets"].map { |subnets_data| Subnet.new(subnet_id: subnets_data['_id'], payload: subnets, node_id: node_id)}
     
      subnets = Subnets.new(limit: subnets["limit"], page: subnets["page"], page_count: subnets["page_count"], subnets_count: subnets["subnets_count"], payload: response, node_id: node_id)

      subnets
    end

    def get_subnet(node_id:,subnet_id:)
     
      path = node(user_id: self.user_id, node_id: node_id) + "/subnets/#{subnet_id}"

      begin
       subnet = client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       subnet = client.get(path)
      end
      subnet = Subnet.new(subnet_id: subnet['_id'], payload: subnet, node_id: node_id)
      subnet 
    end

    # Gets statement by node.
    # @param page [SynapsePayRest::Client]
    # @param per_page [SynapsePayRest::User]  
    # @see https://docs.synapsefi.com/docs/statements-by-user
    def get_node_statements(node_id:,**options)
      [options[:page], options[:per_page]].each do |arg|
        if arg && (!arg.is_a?(Integer) || arg < 1)
          raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
        end
      end

      path = node(user_id: self.user_id, node_id: node_id) + "/statements"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact
      path += '?' + params.join('&') if params.any?

      begin
       statements = client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       statements = client.get(path)
      end

      statements
    end

    # Adds a comment to the transaction's timeline/recent_status fields
    # @param payload: [String]
    def comment_transaction(node_id:,trans_id:,payload:)
      
      path = trans_path(user_id: self.user_id, node_id: node_id) + "/#{trans_id}"

      begin
        trans = client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        trans = client.patch(path, payload)
      end 
      transaction = Transaction.new(trans_id: trans['_id'], payload: trans)
      transaction
    end

    # Cancels this transaction if it has not already settled
    def cancel_transaction(node_id:, trans_id:)
      
      path = trans_path(user_id: self.user_id, node_id: node_id) + "/#{trans_id}"
      begin
        response = client.delete(path)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        response = client.delete(path)
      end 
      response
    end

    def dispute_card_transactions(node_id:, trans_id:)
      
      path = trans_path(user_id: user_id, node_id: node_id) + "/#{trans_id}"
      path += "/dispute"
      payload = {
        "dispute_reason":"CHARGE_BACK"
      }
      begin
        dispute = client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        dispute = client.patch(path, payload)
      end 
      dispute
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

		def nodes_path( **options )
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

    def trans_path(user_id:, node_id:)
      path = "/users/#{user_id}/nodes/#{node_id}/trans"
      path
    end

    def subnet_path(user_id:, node_id:)
      path = "/users/#{user_id}/nodes/#{node_id}/subnets"
      path
    end
	end
end










