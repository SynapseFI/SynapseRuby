# frozen_string_literal: true

module Synapse
  # Wrapper class for /users endpoints
  class User
    # Valid optional args for #get
    VALID_QUERY_PARAMS = %i[query page per_page type full_dehydrate ship force_refresh is_credit
                            subnetid foreign_transaction amount].freeze

    attr_accessor :client, :user_id, :refresh_token, :oauth_key, :expires_in, :payload, :full_dehydrate

    # @param user_id [String]
    # @param refresh_token [String]
    # @param client [Synapse::HTTPClient]
    # @param payload [Hash]
    # @param full_dehydrate [Boolean]
    def initialize(user_id:, refresh_token:, client:, payload:, full_dehydrate:)
      @user_id = user_id
      @client = client
      @refresh_token = refresh_token
      @payload = payload
      @full_dehydrate = full_dehydrate
    end

    # Updates users documents
    # @see https://docs.synapsefi.com/docs/updating-existing-document
    # @param payload [Hash]
    # @return [Synapse::User]
    def user_update(payload:)
      path = get_user_path(user_id: user_id)
      begin
        response = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.patch(path, payload)
      end
      User.new(user_id: response['_id'],
               refresh_token: response['refresh_token'],
               client: client,
               full_dehydrate: false,
               payload: response)
    end

    # Queries the API for a node belonging to user
    # @param node_id [String]
    # @param full_dehydrate [String] (optional)
    #   if true, returns all trans data on node
    # @param force_refresh [String] (optional) if true, force refresh
    #  will attempt updating the account balance and transactions on node
    # @return [Synapse::Node]
    def get_user_node(node_id:, **options)
      options[:full_dehydrate] = 'yes' if options[:full_dehydrate] == true
      options[:full_dehydrate] = 'no' if options[:full_dehydrate] == false
      options[:force_refresh] = 'yes' if options[:force_refresh] == true
      options[:force_refresh] = 'no' if options[:force_refresh] == false

      path = node(node_id: node_id,
                  full_dehydrate: options[:full_dehydrate],
                  force_refresh: options[:force_refresh])

      begin
        node = client.get(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        node = client.get(path)
      end

      node = Node.new(node_id: node['_id'],
                      user_id: user_id,
                      payload: node,
                      full_dehydrate: options[:full_dehydrate] == 'yes',
                      type: node['type'])
    end

    # Queries Synapse API for all nodes belonging to user
    # @param page [String,Integer] (optional) response will default to 1
    # @param per_page [String,Integer] (optional) response will default to 20
    # @param type [String] (optional)
    # @see https://docs.synapsepay.com/docs/node-resources node types
    # @return [Array<Synapse::Nodes>]
    def get_all_user_nodes(**options)
      [options[:page], options[:per_page]].each do |arg|
        raise ArgumentError, "#{arg} must be nil or an Integer >= 1" if arg && (!arg.is_a?(Integer) || arg < 1)
      end
      path = get_user_path(user_id: user_id) + nodes_path(options)

      begin
        nodes = client.get(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        nodes = client.get(path)
      end

      return [] if nodes['nodes'].empty?

      response = nodes['nodes'].map do |node_data|
        Node.new(node_id: node_data['_id'],
                 user_id: node_data['user_id'],
                 payload: node_data, full_dehydrate: 'no',
                 type: node_data['type'])
      end
      nodes = Nodes.new(limit: nodes['limit'],
                        page: nodes['page'],
                        page_count: nodes['page_count'],
                        nodes_count: nodes['node_count'],
                        payload: response)
    end

    # Quaries Synapse oauth API for uto authenitcate user
    # @params scope [Array<Strings>] (optional)
    # @param idempotency_key [String] (optional)
    # @see https://docs.synapsefi.com/docs/get-oauth_key-refresh-token
    def authenticate(**options)
      payload = {
        'refresh_token' => refresh_token
      }
      payload['scope'] = options[:scope] if options[:scope]

      path = oauth_path

      oauth_response = client.post(path, payload, options)
      oauth_key = oauth_response['oauth_key']
      oauth_expires = oauth_response['expires_in']
      self.oauth_key = oauth_key
      self.expires_in = oauth_expires
      client.update_headers(oauth_key: oauth_key)

      oauth_response
    end

    # For registering new fingerprint
    # Supply 2FA device which pin should be sent to
    # @param device [String]
    # @param idempotency_key [String] (optional)
    # @see https://docs.synapsefi.com/docs/get-oauth_key-refresh-token
    # @return API response [Hash]
    def select_2fa_device(device:, **options)
      payload = {
        "refresh_token": refresh_token,
        "phone_number": device
      }
      path = oauth_path
      client.post(path, payload, options)
    end

    # Supply pin for 2FA confirmation
    # @param pin [String]
    # @param idempotency_key [String] (optional)
    # @param scope [Array] (optional)
    # @see https://docs.synapsefi.com/docs/get-oauth_key-refresh-token
    # @return API response [Hash]
    def confirm_2fa_pin(pin:, **options)
      payload = {
        "refresh_token": refresh_token,
        "validation_pin": pin
      }

      payload['scope'] = options[:scope] if options[:scope]

      path = oauth_path

      pin_response = client.post(path, payload, options)
      oauth_key = pin_response['oauth_key']
      oauth_expires = pin_response['expires_in']
      self.oauth_key = oauth_key
      self.expires_in = oauth_expires
      client.update_headers(oauth_key: oauth_key)

      pin_response
    end

    # Queries the Synapse API to get all transactions belonging to a user
    # @return [Array<Synapse::Transactions>]
    # @param page [Integer] (optional) response will default to 1
    # @param per_page [Integer] (optional) response will default to 20
    def get_user_transactions(**options)
      [options[:page], options[:per_page]].each do |arg|
        raise ArgumentError, "#{arg} must be nil or an Integer >= 1" if arg && (!arg.is_a?(Integer) || arg < 1)
      end

      path = transactions_path(user_id: user_id, options: options)

      begin
        trans = client.get(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        trans = client.get(path)
      end

      response = trans['trans'].map do |trans_data|
        Transaction.new(trans_id: trans_data['_id'],
                        payload: trans_data)
      end
      Transactions.new(limit: trans['limit'],
                       page: trans['page'],
                       page_count: trans['page_count'],
                       trans_count: trans['trans_count'],
                       payload: response)
    end

    # Creates Synapse node
    # @note Types of nodes [Card, IB/Deposit-US, Check/Wire Instructions]
    # @param payload [Hash]
    # @param idempotency_key [String] (optional)
    # @see https://docs.synapsefi.com/docs/node-resources
    # @return [Synapse::Node] or [Hash]
    def create_node(payload:, **options)
      path = get_user_path(user_id: user_id)
      path += nodes_path

      begin
        response = client.post(path, payload, options)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.post(path, payload, options)
      end

      if response['nodes']
        nodes = response['nodes'].map do |nodes_data|
          Node.new(user_id: user_id,
                   node_id: nodes_data['_id'],
                   full_dehydrate: false,
                   payload: response,
                   type: nodes_data['type'])
        end
        nodes = Nodes.new(page: response['page'],
                          limit: response['limit'],
                          page_count: response['page_count'],
                          nodes_count: response['node_count'],
                          payload: nodes)
      else
        access_token = response
      end
      access_token || nodes
    end

    # Submit answer to a MFA question using access token from bank login attempt
    # @return [Synapse::Node] or [Hash]
    # @param payload [Hash]
    # @param idempotency_key [String] (optional)
    # @see https://docs.synapsefi.com/docs/add-ach-us-node-via-bank-logins-mfa
    # Please be sure to call ach_mfa again if you have more security questions
    def ach_mfa(payload:, **options)
      path = get_user_path(user_id: user_id)
      path += nodes_path

      begin
        response = client.post(path, payload, options)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.post(path, payload, options)
      end

      if response['nodes']
        nodes = response['nodes'].map do |nodes_data|
          Node.new(user_id: user_id,
                   node_id: nodes_data['_id'],
                   full_dehydrate: false,
                   payload: response,
                   type: nodes_data['type'])
        end
        nodes = Nodes.new(page: response['page'],
                          limit: response['limit'],
                          page_count: response['page_count'],
                          nodes_count: response['node_count'],
                          payload: nodes)
      else
        access_token = response
      end
      access_token || nodes
    end

    # Allows you to upload an Ultimate Beneficial Ownership document
    # @param payload [Hash]
    # @see https://docs.synapsefi.com/docs/generate-ubo-form
    # @return API response
    def create_ubo(payload:)
      path = get_user_path(user_id: user_id)
      path += '/ubo'

      begin
        response = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.patch(path, payload)
      end
      response
    end

    # Gets user statement
    # @param page [Integer]
    # @param per_page [Integer]
    # @see https://docs.synapsefi.com/docs/statements-by-user
    # @return API response
    def get_user_statement(**options)
      path = "#{get_user_path(user_id: user_id)}/statements"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact

      path += "?#{params.join('&')}" if params.any?

      begin
        statements = client.get(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        statements = client.get(path)
      end
      statements
    end

    # Request to ship CARD-US
    # @note Deprecated
    # @param node_id [String]
    # @param payload [Hash]
    # @return [Synapse::Node] or [Hash]
    def ship_card_node(node_id:, payload:)
      path = "#{node(user_id: user_id, node_id: node_id)}?ship=YES"
      begin
        response = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.patch(path, payload)
      end
      Node.new(user_id: user_id,
               node_id: response['_id'],
               full_dehydrate: false,
               payload: response,
               type: response['type'])
    end

    # Request to ship user debit card [Subnet]
    # @param node_id [String]
    # @param payload [Hash]
    # @param subnet_id [String]
    # @return [Synapse::Node] or [Hash]
    def ship_card(node_id:, payload:, subnet_id:)
      path = node(user_id: user_id, node_id: node_id) + "/subnets/#{subnet_id}/ship"

      begin
        response = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.patch(path, payload)
      end
      Subnet.new(subnet_id: response['subnet_id'], payload: response, node_id: response['node_id'])
    end

    # Resets debit card number, cvv, and expiration date
    # @note Deprecated
    # @see https://docs.synapsefi.com/docs/reset-debit-card
    # @param node_id [String]
    # @return [Synapse::Node] or [Hash]
    def reset_card_node(node_id:)
      path = "#{node(user_id: user_id, node_id: node_id)}?reset=YES"
      payload = {}
      begin
        response = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.patch(path, payload)
      end
      Node.new(user_id: user_id,
               node_id: response['_id'],
               full_dehydrate: false,
               payload: response,
               type: response['type'])
    end

    # Creates a new transaction in the API belonging to the provided node
    # @param node_id [String]
    # @param payload [Hash]
    # @param idempotency_key [String] (optional)
    # @return [Synapse::Transaction]
    def create_transaction(node_id:, payload:, **options)
      path = trans_path(user_id: user_id, node_id: node_id)
      begin
        transaction = client.post(path, payload, options)
      rescue Synapse::Error::Unauthorized
        authenticate
        transaction = client.post(path, payload, options)
      end
      transaction = Transaction.new(trans_id: transaction['_id'],
                                    payload: transaction,
                                    node_id: node_id)
    end

    # Queries the API for a transaction belonging to the supplied node by transaction id
    # @param node_id [String]
    # @param trans_id [String] id of the transaction to find
    # @return [Synapse::Transaction]
    def get_node_transaction(node_id:, trans_id:)
      path = node(user_id: user_id, node_id: node_id) + "/trans/#{trans_id}"

      begin
        trans = client.get(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        trans = client.get(path)
      end
      Transaction.new(trans_id: trans['_id'],
                      payload: trans,
                      node_id: node_id)
    end

    # Queries the API for all transactions belonging to the supplied node
    # @param node_id [String] node to which the transaction belongs
    # @param page [Integer] (optional) response will default to 1
    # @param per_page [Integer] (optional) response will default to 20
    # @return [Array<Synapse::Transaction>]
    def get_all_node_transaction(node_id:, **options)
      [options[:page], options[:per_page]].each do |arg|
        raise ArgumentError, "#{arg} must be nil or an Integer >= 1" if arg && (!arg.is_a?(Integer) || arg < 1)
      end

      path = "#{node(user_id: user_id, node_id: node_id)}/trans"

      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact

      path += "?#{params.join('&')}" if params.any?

      begin
        trans = client.get(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        trans = client.get(path)
      end
      response = trans['trans'].map do |trans_data|
        Transaction.new(trans_id: trans_data['_id'],
                        payload: trans_data,
                        node_id: node_id)
      end
      Transactions.new(limit: trans['limit'],
                       page: trans['page'],
                       page_count: trans['page_count'],
                       trans_count: trans['trans_count'],
                       payload: response)
    end

    # Verifies microdeposits for a node
    # @param node_id [String]
    # @param payload [Hash]
    def verify_micro_deposit(node_id:, payload:)
      path = node(user_id: user_id, node_id: node_id)
      begin
        response = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.patch(path, payload)
      end
      Node.new(user_id: user_id,
               node_id: response['_id'],
               full_dehydrate: false,
               payload: response,
               type: response['type'])
    end

    # Reinitiate microdeposits on a node
    # @param node_id [String]
    def reinitiate_micro_deposit(node_id:)
      payload = {}
      path = "#{node(user_id: user_id, node_id: node_id)}?resend_micro=YES"
      begin
        response = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.patch(path, payload)
      end
      Node.new(user_id: user_id,
               node_id: response['_id'],
               full_dehydrate: false,
               payload: response,
               type: response['type'])
    end

    # Generate tokenized info for Apple Wallet
    # @param node_id [String]
    # @param payload [Hash]
    # @see https://docs.synapsefi.com/docs/generate-applepay-token
    def generate_apple_pay_token(node_id:, payload:)
      path = "#{node(user_id: user_id, node_id: node_id)}/applepay"
      begin
        response = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.patch(path, payload)
      end
      response
    end

    # Update supp_id, nickname, etc. for a node
    # @param node_id [String]
    # @param payload [Hash]
    # @see https://docs.synapsefi.com/docs/update-info
    # @return [Synapse::Node]
    def update_node(node_id:, payload:)
      path = node(user_id: user_id, node_id: node_id)

      begin
        update = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        update = client.patch(path, payload)
      end
      Node.new(node_id: node_id,
               user_id: user_id,
               payload: update,
               full_dehydrate: false,
               type: update['type'])
    end

    # @param node_id [String]
    def delete_node(node_id:)
      path = node(user_id: user_id, node_id: node_id)

      begin
        delete = client.delete(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        delete = client.delete(path)
      end
      delete
    end

    # Initiates dummy transactions to a node
    # @param node_id [String]
    # @param is_credit [String]
    # @param foreign_transaction [String]
    # @param subnetid [String]
    # @param type [String]
    # @see https://docs.synapsefi.com/docs/trigger-dummy-transactions
    def dummy_transactions(node_id:, **options)
      path = "#{node(user_id: user_id, node_id: node_id)}/dummy-tran"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact
      path += "?#{params.join('&')}" if params.any?

      begin
        response = client.get(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.get(path)
      end
      response
    end

    # Adds comment to the transactions
    # @param node_id [String]
    # @param trans_id [String]
    # @param payload [Hash]
    # @return [Synapse::Transaction]
    def comment_transaction(node_id:, trans_id:, payload:)
      path = trans_path(user_id: user_id, node_id: node_id) + "/#{trans_id}"

      begin
        trans = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        trans = client.patch(path, payload)
      end
      Transaction.new(trans_id: trans['_id'], payload: trans)
    end

    # Cancels transaction if it has not already settled
    # @param node_id
    # @param trans_id
    # @return API response [Hash]
    def cancel_transaction(node_id:, trans_id:)
      path = trans_path(user_id: user_id, node_id: node_id) + "/#{trans_id}"
      begin
        response = client.delete(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        response = client.delete(path)
      end
      response
    end

    # Dispute a transaction for a user
    # @param node_id
    # @param trans_id
    # @see https://docs.synapsefi.com/docs/dispute-card-transaction
    # @return API response [Hash]
    def dispute_card_transactions(node_id:, trans_id:, payload:)
      path = trans_path(user_id: user_id, node_id: node_id) + "/#{trans_id}"
      path += '/dispute'
      begin
        dispute = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        dispute = client.patch(path, payload)
      end
      dispute
    end

    # Creates subnet for a node debit card or act/rt number
    # @param node_id [String]
    # @param payload [Hash]
    # @param idempotency_key [String] (optional)
    # @return [Synapse::Subnet]
    def create_subnet(node_id:, payload:, **options)
      path = subnet_path(user_id: user_id, node_id: node_id)
      begin
        subnet = client.post(path, payload, options)
      rescue Synapse::Error::Unauthorized
        authenticate
        subnet = client.post(path, payload, options)
      end
      Subnet.new(subnet_id: subnet['_id'], payload: subnet, node_id: node_id)
    end

    # Updates subnet debit card and act/rt number
    # @param node_id [String]
    # @param payload [Hash]
    # @param subnet_id [String]
    # @return [Synapse::Subnet]
    def update_subnet(node_id:, payload:, subnet_id:, **_options)
      path = subnet_path(user_id: user_id, node_id: node_id, subnet_id: subnet_id)
      begin
        subnet = client.patch(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        subnet = client.patch(path, payload)
      end
      Subnet.new(subnet_id: subnet['_id'], payload: subnet, node_id: node_id)
    end

    # Gets all node subnets
    # @param node_id [String]
    # @param page [Integer]
    # @param per_page [Integer]
    # @see https://docs.synapsefi.com/docs/all-node-subnets
    def get_all_subnets(node_id:, **options)
      [options[:page], options[:per_page]].each do |arg|
        raise ArgumentError, "#{arg} must be nil or an Integer >= 1" if arg && (!arg.is_a?(Integer) || arg < 1)
      end

      path = "#{node(user_id: user_id, node_id: node_id)}/subnets"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact
      path += "?#{params.join('&')}" if params.any?

      begin
        subnets = client.get(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        subnets = client.get(path)
      end

      response = subnets['subnets'].map do |subnets_data|
        Subnet.new(subnet_id: subnets_data['_id'],
                   payload: subnets,
                   node_id: node_id)
      end
      Subnets.new(limit: subnets['limit'],
                  page: subnets['page'],
                  page_count: subnets['page_count'],
                  subnets_count: subnets['subnets_count'],
                  payload: response,
                  node_id: node_id)
    end

    # Queries a node for a specific subnet by subnet_id
    # @param node_id [String] id of node
    # @param subnet_id [String,void] (optional) id of a subnet to look up
    # @param full_dehydrate [String](optional)
    # @return [Synapse::Subnet]
    def get_subnet(node_id:, subnet_id:, **options)
      path = node(user_id: user_id, node_id: node_id) + "/subnets/#{subnet_id}"

      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact
      path += "?#{params.join('&')}" if params.any?

      begin
        subnet = client.get(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        subnet = client.get(path)
      end
      Subnet.new(subnet_id: subnet['_id'], payload: subnet, node_id: node_id)
    end

    # Gets statement by node
    # @param page [Integer]
    # @param per_page [Integer]
    # @see https://docs.synapsefi.com/docs/statements-by-user
    # @return API response [Hash]
    def get_node_statements(node_id:, **options)
      [options[:page], options[:per_page]].each do |arg|
        raise ArgumentError, "#{arg} must be nil or an Integer >= 1" if arg && (!arg.is_a?(Integer) || arg < 1)
      end

      path = "#{node(user_id: user_id, node_id: node_id)}/statements"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact
      path += "?#{params.join('&')}" if params.any?

      begin
        statements = client.get(path)
      rescue Synapse::Error::Unauthorized
        authenticate
        statements = client.get(path)
      end

      statements
    end

    # Gets statement by node on demand
    # @param payload [Hash]
    # @see https://docs.synapsefi.com/reference#generate-node-statements
    # @return API response [Hash]
    def generate_node_statements(node_id:, payload:)
      path = "#{node(user_id: user_id, node_id: node_id)}/statements"

      begin
        statements = client.post(path, payload)
      rescue Synapse::Error::Unauthorized
        authenticate
        statements = client.post(path, payload)
      end

      statements
    end

    private

    def oauth_path
      "/oauth/#{user_id}"
    end

    def get_user_path(user_id:, **options)
      path = "/users/#{user_id}"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact
      path += "?#{params.join('&')}" if params.any?
      path
    end

    def transactions_path(user_id:, **options)
      path = "/users/#{user_id}/trans"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact

      path += "?#{params.join('&')}" if params.any?
      path
    end

    def nodes_path(**options)
      path = '/nodes'

      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact

      path += "?#{params.join('&')}" if params.any?

      path
    end

    def node(node_id:, **options)
      path = "/users/#{user_id}/nodes/#{node_id}"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact

      path += "?#{params.join('&')}" if params.any?

      path
    end

    def trans_path(user_id:, node_id:)
      "/users/#{user_id}/nodes/#{node_id}/trans"
    end

    def subnet_path(user_id:, node_id:, subnet_id: nil)
      if subnet_id
        "/users/#{user_id}/nodes/#{node_id}/subnets/#{subnet_id}"
      else
        "/users/#{user_id}/nodes/#{node_id}/subnets"
      end
    end
  end
end
