require 'synapse_fi'


module Synapse
	# Initializes various wrapper settings such as development mode and request
 	# header values

    class Client
        VALID_QUERY_PARAMS = [:query, :page, :per_page, :full_dehydrate, :radius, :zip, :lat, :lon, :limit, :currency, :ticker_symbol].freeze

    	attr_accessor :http_client

    	attr_reader :client_id

    	# Alias for #http_client
    	alias_method :client, :http_client

    	# @param client_id [String] should be stored in environment variable
        # @param client_secret [String] should be stored in environment variable
        # @param ip_address [String] user's IP address
        # @param fingerprint [String] a hashed value, either unique to user or static
        # @param development_mode [String] default true
        # @param raise_for_202 [Boolean]
        # @param logging [Boolean] (optional) logs to stdout when true
        # @param log_to [String] (optional) file path to log to file (logging must be true)
        def initialize(client_id:, client_secret:, ip_address:, fingerprint:nil,development_mode: true, raise_for_202:nil, **options)
            base_url = if development_mode
                            'https://uat-api.synapsefi.com/v3.1'
                        else
                            'https://api.synapsefi.com/v3.1'
                        end
            @client_id = client_id
            @client_secret = client_secret
            @http_client  = HTTPClient.new(base_url: base_url,
                                             client_id: client_id,
                                             client_secret: client_secret,
                                             fingerprint: fingerprint,
                                             ip_address: ip_address,
                                             raise_for_202: raise_for_202,
                                             **options
                                             )
        end

        # Queries Synapse API to create a new user
        # @param payload [Hash]
        # @param idempotency_key [String] (optional)
        # @param ip_address [String] (optional)
        # @param fingerprint [String] (optional)
        # @return [Synapse::User]
        # @see https://docs.synapsepay.com/docs/create-a-user payload structure
        def create_user(payload:, ip_address:, **options)
            client.update_headers(ip_address: ip_address, fingerprint: options[:fingerprint])

            response = client.post(user_path,payload, options)

            User.new(user_id:           response['_id'],
                   refresh_token:     response['refresh_token'],
                   client:            client,
                   full_dehydrate:    "no",
                   payload:           response
                  )
    	end

        # Update headers in HTTPClient class
        # for API request headers
        # @param fingerprint [Hash]
        # @param idemopotency_key [Hash]
        # @param ip_address [Hash]
        def update_headers(fingerprint:nil, idemopotency_key:nil, ip_address:nil)
            client.update_headers(fingerprint: fingerprint, idemopotency_key: idemopotency_key, ip_address: ip_address)
        end

      	# Queries Synapse API for a user by user_id
      	# @param user_id [String] id of the user to find
        # @param full_dehydrate [String] (optional) if true, returns all KYC on user
        # @param ip_address [String] (optional)
        # @param fingerprint [String] (optional)
        # @see https://docs.synapsefi.com/docs/get-user
        # @return [Synapse::User]
      	def get_user(user_id:, **options)
      		raise ArgumentError, 'client must be a Synapse::Client' unless self.is_a?(Client)
      		raise ArgumentError, 'user_id must be a String' unless user_id.is_a?(String)

      		options[:full_dehydrate] = "yes" if options[:full_dehydrate] == true
      		options[:full_dehydrate] = "no" if options[:full_dehydrate] == false

            client.update_headers(ip_address: options[:ip_address], fingerprint: options[:fingerprint])

      		path = user_path(user_id: user_id, full_dehydrate: options[:full_dehydrate])
      		response = client.get(path)

      		User.new(user_id:         response['_id'],
                   refresh_token:   response['refresh_token'],
                   client:          client,
                   full_dehydrate:  options[:full_dehydrate] == "yes" ? true : false,
                   payload:         response
                  )
      	end

      	# Queries Synapse API for platform users
      	# @param query [String] (optional) response will be filtered to
        # users with matching name/email
        # @param page [Integer] (optional) response will default to 1
        # @param per_page [Integer] (optional) response will default to 20
        # @return [Array<Synapse::Users>]
      	def get_users(**options)
      		path = user_path(options)
      		response = client.get(path)
      		return [] if response["users"].empty?
      		users = response["users"].map { |user_data| User.new(user_id:         user_data['_id'],
                                                               refresh_token:   user_data['refresh_token'],
                                                               client:          client,
                                                               full_dehydrate:  "no",
                                                               payload:         user_data
                                                               )}
      		Users.new(limit:       response["limit"],
                    page:        response["page"],
                    page_count:  response["page_count"],
                    user_count:  response["user_count"],
                    payload:     users,
                    http_client: client
                   )
      	end

        # Queries Synapse for all transactions on platform
        # @param page [Integer] (optional) response will default to 1
        # @param per_page [Integer] (optional) response will default to 20
        # @return [Array<Synapse::Transactions>]
      	def get_all_transaction(**options)
      		path = '/trans'

      		params = VALID_QUERY_PARAMS.map do |p|
      			options[p] ? "#{p}=#{options[p]}" : nil
      		end.compact

      		path += '?' + params.join('&') if params.any?

      		trans = client.get(path)

      		return [] if trans["trans"].empty?
      		response = trans["trans"].map { |trans_data| Transaction.new(trans_id: trans_data['_id'], payload: trans_data)}
      		Transactions.new(limit:       trans["limit"],
                           page:        trans["page"],
                           page_count:  trans["page_count"],
                           trans_count: trans["trans_count"],
                           payload:     response
                           )
      	end

        # Queries Synapse API for all nodes belonging to platform
        # @param page [Integer] (optional) response will default to 1
        # @param per_page [Integer] (optional) response will default to 20
        # @return [Array<Synapse::Nodes>]
      	def get_all_nodes(**options)
      		[options[:page], options[:per_page]].each do |arg|
                if arg && (!arg.is_a?(Integer) || arg < 1)
                    raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
                end
            end
      		path = nodes_path(options: options)
      		nodes = client.get(path)

      		return [] if nodes["nodes"].empty?
      		response = nodes["nodes"].map { |node_data| Node.new(node_id:        node_data['_id'],
                                                               user_id:        node_data['user_id'],
                                                               payload:        node_data,
                                                               full_dehydrate: "no"
                                                               )}
      		Nodes.new(limit:       nodes["limit"],
                    page:        nodes["page"],
                    page_count:  nodes["page_count"],
                    nodes_count: nodes["node_count"],
                    payload:     response
                   )
      	end

        # Queries Synapse API for all institutions available for bank logins
        # @param page [Integer] (optional) response will default to 1
        # @param per_page [Integer] (optional) response will default to 20
        # @return API response [Hash]
      	def get_all_institutions(**options)
            client.get(institutions_path(options))
      	end

        # Queries Synapse API to create a webhook subscriptions for platform
        # @param scope [Hash]
        # @param idempotency_key [String] (optional)
        # @see https://docs.synapsefi.com/docs/create-subscription
        # @return [Synapse::Subscription]
      	def create_subscriptions(scope:, **options)
      		response = client.post(subscriptions_path , scope, options)

      		Subscription.new(subscription_id: response["_id"], url: response["url"], payload: response)
      	end

        # Queries Synapse API for all platform subscriptions
        # @param page [Integer] (optional) response will default to 1
        # @param per_page [Integer] (optional) response will default to 20
        # @return [Array<Synapse::Subscriptions>]
      	def get_all_subscriptions(**options)
      		subscriptions = client.get(subscriptions_path(options))

      		return [] if subscriptions["subscriptions"].empty?
      		response = subscriptions["subscriptions"].map { |subscription_data| Subscription.new(subscription_id: subscription_data["_id"],
                                                                                               url: subscription_data["url"],
                                                                                               payload: subscription_data)}
      		Subscriptions.new(limit:               subscriptions["limit"],
                            page:                subscriptions["page"],
                            page_count:          subscriptions["page_count"],
                            subscriptions_count: subscriptions["subscription_count"],
                            payload:             response
                            )
      	end

        # Queries Synapse API for a subscription by subscription_id
        # @param subscription_id [String]
        # @return [Synapse::Subscription]
      	def get_subscription(subscription_id:)
      		path = subscriptions_path + "/#{subscription_id}"
      		response = client.get(path)
      		Subscription.new(subscription_id: response["_id"], url: response["url"], payload: response)
      	end

        # Updates subscription platform subscription
        # @param subscription_id [String]
        # @param body [Hash]
        # see https://docs.synapsefi.com/docs/update-subscription
        # @return [Synapse::Subscription]
        def update_subscriptions(subscription_id:, body:)
            path = subscriptions_path + "/#{subscription_id}"

            response = client.patch(path, body)
            Subscription.new(subscription_id: response["_id"], url: response["url"], payload: response)
        end

        # Returns all of the webhooks belonging to client
        # @param page [Integer] (Optional)
        # @param per_page [Integer] (Optional)
        # @return [Hash]
        def webhook_logs(**options)
            path = subscriptions_path + "/logs"

            params = VALID_QUERY_PARAMS.map do |p|
                options[p] ? "#{p}=#{options[p]}" : nil
            end.compact

            path += '?' + params.join('&') if params.any?

            client.get(path)
        end

      	# Issues public key for client
      	# @param scope [String]
        # @param user_id [String] (Optional)
        # @see https://docs.synapsefi.com/docs/issuing-public-key
      	# @note valid scope "OAUTH|POST,USERS|POST,USERS|GET,USER|GET,USER|PATCH,SUBSCRIPTIONS|GET,SUBSCRIPTIONS|POST,SUBSCRIPTION|GET,SUBSCRIPTION|PATCH,CLIENT|REPORTS,CLIENT|CONTROLS"
      	def issue_public_key(scope:, user_id = nil)
      		path = '/client?issue_public_key=YES'

            path += "&scope=#{scope}"

            path += "&user_id=#{user_id}" if user_id

      		response = client.get(path)
      		response[ "public_key_obj"]
      	end

        # Queries Synapse API for ATMS nearby
        # @param zip [String]
        # @param radius [String]
        # @param lat [String]
        # @param lon [String]
        # @see https://docs.synapsefi.com/docs/locate-atms
        # @return [Hash]
        def locate_atm(**options)
            params = VALID_QUERY_PARAMS.map do |p|
                options[p] ? "#{p}=#{options[p]}" : nil
            end.compact

            path = "/nodes/atms?"
            path += params.join('&') if params.any?
            atms = client.get(path)
            atms
        end

        # Queries Synapse API for Crypto Currencies Quotes
        # @return API response [Hash]
        def get_crypto_quotes()
            path = '/nodes/crypto-quotes'
            params = VALID_QUERY_PARAMS.map do |p|
                options[p] ? "#{p}=#{options[p]}" : nil
            end.compact

            path += '?' + params.join('&') if params.any?
            quotes = client.get(path)
            quotes
        end

        # Queries Synapse API for Crypto Currencies Market data
        # @param limit [Integer]
        # @param currency [String]
        # @return API response [Hash]
        def get_crypto_market_data(**options)
            path = '/nodes/crypto-market-watch'

            params = VALID_QUERY_PARAMS.map do |p|
                options[p] ? "#{p}=#{options[p]}" : nil
            end.compact

            path += '?' + params.join('&') if params.any?

            data = client.get(path)
            data
        end

        # Queries Synapse API for Trade Market data
        # @param ticker_symbol [String]
        # @return API response [Hash]
        def get_trade_market_data(**options)
            path = '/nodes/trade-market-watch'

            params = VALID_QUERY_PARAMS.map do |p|
                options[p] ? "#{p}=#{options[p]}" : nil
            end.compact

            path += '?' + params.join('&') if params.any?

            market_data = client.get(path)
            market_data
        end

        # Queries Synapse API for Routing Verification
        # @param payload [Hash]
        # @return API response [Hash]
        def routing_number_verification(payload:)
            path = '/routing-number-verification'

            response = client.post(path,payload)
            response
        end

        # Queries Synapse API for Address Verification
        # @param payload [Hash]
        # @return API response [Hash]
        def address_verification(payload:)
            path = '/address-verification'

            response = client.post(path,payload)
            response
        end

        private
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



