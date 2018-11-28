require 'json'
require_relative './http_request'
require_relative './user'
require_relative './users'
require_relative './transaction'
require_relative './transactions'
require_relative './node'
require_relative './nodes'
require_relative './subscription'
require_relative './subscriptions'
require 'pp'



module SynapsePayRest
	# Initializes various wrapper settings such as development mode and request
 	# header values. Also stores and initializes endpoint class instances 
  	# (Users, Nodes, Transactions) for making API calls.

  class Client 

  	# to do: take into account params 

  	VALID_QUERY_PARAMS = [:query, :page, :per_page, :full_dehydrate].freeze

  	attr_accessor :http_client

  	attr_reader :client_id

  	# Alias for #http_client
  	alias_method :client, :http_client


  	# @param client_id [String] should be stored in environment variable
    # @param client_secret [String] should be stored in environment variable
    # @param ip_address [String] user's IP address
    # @param fingerprint [String] a hashed value, either unique to user or static
    # @param development_mode [String] default true
   

    # TO DO
	 	# @param logging [Boolean] (optional) logs to stdout when true
    	# @param log_to [String] (optional) file path to log to file (logging must be true)
  	def initialize(client_id:, client_secret:, ip_address:, fingerprint:nil,development_mode: true, **options)
  		base_url = if development_mode
                   'https://uat-api.synapsefi.com/v3.1'
                 else
                   'https://api.synapsefi.com/v3.1'
                 end

        @http_client  = HTTPClient.new(base_url: base_url,
                                     client_id: client_id,
                                     client_secret: client_secret,
                                     fingerprint: fingerprint,
                                     ip_address: ip_address,
                                     **options)  

    end

    # Sends a POST request to /users endpoint to create a new user, and returns
    # user object
    # 
    # @param payload [Hash]
    # @see https://docs.synapsepay.com/docs/create-a-user payload structure
    # 
    #TODO:
    #Create Error handeling from http request 
   
    def create_user(payload:)
    	raise ArgumentError, 'client must be a SynapsePayRest::Client' unless self.is_a?(Client)
        #if [logins, phone_numbers, legal_names].any? { |arg| !arg.is_a? Array}
         # raise ArgumentError, 'logins/phone_numbers/legal_names must be Array'
        #end
        #if [logins, phone_numbers, legal_names].any?(&:empty?)
          #raise ArgumentError, 'logins/phone_numbers/legal_names cannot be empty'
        #end
        #unless logins.first.is_a? Hash
          #raise ArgumentError, 'logins must contain at least one hash {email: (required), password:, read_only:}'
        #end
        #unless logins.first[:email].is_a?(String) && logins.first[:email].length > 0
         # raise ArgumentError, 'logins must contain at least one hash with :email key'
        #end

        #payload = payload_for_create(**options)
        #puts payload
        #raise 
        response = client.post(user_path,payload) 
      
        
        user = User.new(
          user_id:                response['_id'],
          refresh_token:     response['refresh_token'],
          client:            client,
          full_dehydrate:    "no",
          payload:           response
        )

        user.authenticate
	end

	# Queries the API for a user by id and returns a User instances if found
	# options for query parameters such as :full_dehydrate
	# @param id [String] id of the user to find
    # @param options[:full_dehydrate] [String] (optional) if tru, returns all KYC on user
    # optional params: options[:query], options[:query], options[:page], options[:per_page], options[:show_refresh_tokens:]
    # @ see https://docs.synapsefi.com/docs/get-users for optional params    
	def get_user(user_id:, **options)
		raise ArgumentError, 'client must be a SynapsePayRest::Client' unless self.is_a?(Client)
		raise ArgumentError, 'user_id must be a String' unless user_id.is_a?(String)

		options[:full_dehydrate] = "yes" if options[:full_dehydrate] == true
		options[:full_dehydrate] = "no" if options[:full_dehydrate] == false

		path = user_path(user_id: user_id, full_dehydrate: options[:full_dehydrate])
		response = client.get(path)

		user = User.new(
          user_id:                response['_id'],
          refresh_token:     response['refresh_token'],
          client:            client,
          full_dehydrate:    options[:full_dehydrate] == "yes" ? true : false,
          payload:           response
        )
		
    user.authenticate
	end

	# change users scope after creating a user
	# scope changes during oauth 
	# scope must be in array  
  def change_user_scope(user_id:, **scope)
  	raise ArgumentError, 'client must be a SynapsePayRest::Client' unless self.is_a?(Client)
	  raise ArgumentError, 'user_id must be a String' unless user_id.is_a?(String)
	  if [scope[:scope]].any? { |arg| !arg.is_a? Array}
        raise ArgumentError, 'scope must be Array'
    end

  	refresh_token = refresh_token(user_id: user_id)
  	oauth_path = oauth_path(user_id)
  	authenticate(refresh_token, oauth_path, scope)
  	nil 
  end

	# returns an Users instance of all users 
	# payload for users object contains an array of Users instances
	# @param query [String] (optional) response will be filtered to 
    # users with matching name/email
    # @param page [String,Integer] (optional) response will default to 1
    # @param per_page [String,Integer] (optional) response will default to 20 
    # @note users created this way are not automatically OAuthed
	def get_users(page: nil, per_page: nil, query: nil)
		raise ArgumentError, 'client must be a SynapsePayRest::Client' unless self.is_a?(Client)
    [page, per_page].each do |arg|
      if arg && (!arg.is_a?(Integer) || arg < 1)
        raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
      end
    end
    if query && !query.is_a?(String)
      raise ArgumentError, 'query must be a String'
    end

		path = user_path(page: page, per_page: per_page, query: query)
		response = client.get(path)
		return [] if response["users"].empty?
		users = response["users"].map { |user_data| User.new(user_id: user_data['_id'], refresh_token: user_data['refresh_token'], client: client, full_dehydrate: "no", payload: user_data)}
		users = Users.new(limit: response["limit"], page: response["page"], page_count: response["page_count"], user_count: response["user_count"], payload: users, http_client: client)
		
    users
	end

	  # Queries the API for all transactions belonging to the client platform
	  # returns Transactions instances.
	  # @param options[page] [String,Integer] (optional) response will default to 1
	  # @param optiions[per_page] [String,Integer] (optional) response will default to 20
	def get_transaction(**options)
		path = '/trans'

		params = VALID_QUERY_PARAMS.map do |p|
			options[p] ? "#{p}=#{options[p]}" : nil
		end.compact

		path += '?' + params.join('&') if params.any?

		trans = client.get(path)
		
		return [] if trans["trans"].empty?
		response = trans["trans"].map { |trans_data| Transaction.new(trans_id: trans_data['_id'], payload: trans_data)}
		trans = Transactions.new(limit: trans["limit"], page: trans["page"], page_count: trans["page_count"], trans_count: trans["trans_count"], payload: response)
		trans 
		
	end

	  # Queries the API for all nodes belonging to the platform 
      # 
      # @param options[page] [String,Integer] (optional) response will default to 1
      # @param options[per_page] [String,Integer] (optional) response will default to 20
      # 
      # @returns Nodes instances 
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

	def get_all_institutions(**options)
		client.get(institutions_path(options))
	end
	  # Creates a new subscription in the API and returns a Subscription instance from the
      # response data.
      # @param scope [Array<String>]
      # @param url [String]
      # @return [SynapsePayRest::Subscription]
	def create_subscriptions(scope:, url:)
		raise ArgumentError, 'client must be a SynapsePayRest::Client' unless self.is_a?(Client)
        raise ArgumentError, 'url must be a String' unless url.is_a? String
        raise ArgumentError, 'scope must be an Array' unless scope.is_a? Array
		payload = {
          'scope' => scope,
          'url' => url,
        }
		
		response = client.post(subscriptions_path , payload)

		subscriptions = Subscription.new(subscription_id: response["_id"], url: response["url"], http_client: client, payload: response)
	end

	  # Queries the API for all subscriptions and returns them as Subscriptions instances
      # @param options[page] [String,Integer] (optional) response will default to 1
      # @param options[per_page] [String,Integer] (optional) response will default to 20
      # 
      # @return [Array<SynapsePayRest::Subscriptions>]
	def get_all_subscriptions(**options)
		subscriptions = client.get(subscriptions_path(options))
		
		return [] if subscriptions["subscriptions"].empty?
		response = subscriptions["subscriptions"].map { |subscription_data| Subscription.new(subscription_id: subscription_data["_id"], url: subscription_data["url"], http_client: client, payload: subscription_data)}
		subscriptions = Subscriptions.new(limit: subscriptions["limit"], page: subscriptions["page"], page_count: subscriptions["page_count"], subscriptions_count: subscriptions["subscription_count"], payload: response, http_client: client)
	end


	  # Queries the API for a subscription by subscription_id and returns a Subscription instances if found.
      # @param id [String] id of the subscription to find
      # @return [SynapsePayRest::Subscription]
	def get_subscription(subscription_id)
		raise ArgumentError, 'client must be a SynapsePayRest::Client' unless self.is_a?(Client)
    raise ArgumentError, 'subscription_id must be a String' unless subscription_id.is_a?(String)
		path = subscriptions_path + "/#{subscription_id}"
		response = client.get(path)
		subscription = Subscription.new(subscription_id: response["_id"], url: response["url"], http_client: client, payload: response)
	end

	
      # Updates the given key value pairs [is_active, url, scope]
      # see https://docs.synapsefi.com/docs/update-subscription
      # @param is_active [boolean]
      # @param url [String]
      # @param scope [Array<String>]
      # @return [SynapsePayRest::Subscription] new instance corresponding to same API record
	def update_subscriptions(subscription_id:, **options)
		raise ArgumentError, 'client must be a SynapsePayRest::Client' unless self.is_a?(Client)
		raise ArgumentError, 'scope must be an array' unless options[:scope].is_a?(Array)
		path = subscriptions_path + "/#{subscription_id}"

	
		payload = {}

		payload["url"] = options[:url] if options[:url]
		payload["scope"] = options[:scope] if options[:scope]

		response = client.patch(path, payload)
		subscriptions = Subscription.new(subscription_id: response["_id"], url: response["url"], http_client: client, payload: response)
	end
	
	# Issues public key for client.
	# @param client [SynapsePayRest::Client]
	# @param scope [String]
	# 
	# "OAUTH|POST,USERS|POST,USERS|GET,USER|GET,USER|PATCH,SUBSCRIPTIONS|GET,SUBSCRIPTIONS|POST,SUBSCRIPTION|GET,SUBSCRIPTION|PATCH,CLIENT|REPORTS,CLIENT|CONTROLS"
	def issue_public_key(scope:)
		raise ArgumentError, 'scope must be a string' unless scope.is_a?(String)
		path = '/client?issue_public_key=YES'
		path += "&scope=#{scope}"
		response = client.get(path)
		response[ "public_key_obj"]
	end
 

  private

  	# grabs the refresh token and formats a refresh token payload 
	def refresh_token(user_id:)
		response = get_user(user_id:user_id)
		refresh_token = response.refresh_token
	
		refresh_token = {"refresh_token" => refresh_token} 
	end

	# options payload to change scope of oauth 
	def authenticate(refresh_token, oauth_path, **options)
		oauth_key = client.post(oauth_path, refresh_token, options)
		oauth_key = oauth_key['oauth_key']
		client.update_headers(oauth_key: oauth_key)
		nil
	end

	def oauth_path(user_id)
		path = "/oauth/#{user_id}"
	end

    def user_path(user_id: nil, **options)
    	
    	path = "/users"
    	path += "/#{user_id}" if user_id

    	params = VALID_QUERY_PARAMS.map do |p|
			options[p] ? "#{p}=#{options[p]}" : nil
		end.compact

		path += '?' + params.join('&') if params.any?
    	path
    end

    def transactions_path(user_id: nil, node_id: nil, **options)
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

    def institutions_path(**options)
    	path = "/institutions"
    	params = VALID_QUERY_PARAMS.map do |p|
			options[p] ? "#{p}=#{options[p]}" : nil
		end.compact

		path += '?' + params.join('&') if params.any?
    	path
    end
    
    def subscriptions_path(**options)
    	path = "/subscriptions"
    	params = VALID_QUERY_PARAMS.map do |p|
			options[p] ? "#{p}=#{options[p]}" : nil
		end.compact

		path += '?' + params.join('&') if params.any?
    	path
    end

  end
end

args = {
  client_id:        "client_id_IvSkbeOZAJlmM4ay81EQC0oD7WnP6X9UtRhKs5Yz",
  client_secret:    "client_secret_1QFnWfLBi02r5yAKhovw8Rq9MNPgCkZE4ulHxdT0",
  fingerprint:      "static_pin",
  ip_address:       '127.0.0.1',
  development_mode: true
}

args = args


puts "========Client Object Created==========" 

client  = SynapsePayRest::Client.new(args) 

puts "========Gets a User=========="


user = "5bd9e16314c7fa00a3076960"
user = client.get_user(user_id: user,full_dehydrate: true)


puts "========Ship Card-US Node ==========" 
card_us = "5bfed4e8bab475008ea4e390"
payload = {
  "fee_node_id":"5bef0dbdb95dfb00bfdc2473",
  "expedite":true
}

pp user.ship_card(node_id:card_us ,payload:payload)


