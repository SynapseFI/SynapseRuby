module SynapsePayRest

	class Node

    # valid query params 
    VALID_QUERY_PARAMS = [:page, :per_page].freeze

		attr_reader :node_id, :user_id, :payload, :full_dehydrate, :http_client, :user

		attr_accessor 

		def initialize(node_id:, user_id:,payload:, full_dehydrate:, http_client:, user:nil)
			@node_id = node_id
			@full_dehydrate = full_dehydrate
			@http_client = http_client
			@user_id = user_id 
      @user = user 
			@payload = payload
		end

    def ship_card(payload:)
    
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "?ship=YES"
      
      begin
       response = http_client.patch(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       response = http_client.patch(path,payload)
      end
      response
    end

    def reset_debit_card(payload:)
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "?reset=YES"
  
      begin
       response = http_client.patch(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       response = http_client.patch(path,payload)
      end
      response
    end

    def create_transaction(payload:)
      path = trans_path(user_id: self.user_id, node_id: self.node_id)

      begin
       transaction = http_client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       transaction = http_client.post(path,payload)
      end
      transaction = Transaction.new(trans_id: transaction['_id'], payload: transaction, node_id: self.node_id, user: self.user, http_client: self.http_client)
    end

    def get_transaction(trans_id:)
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "/trans/#{trans_id}" 
     
      begin
        trans = http_client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        trans = http_client.get(path)
      end 
      transaction = Transaction.new(trans_id: trans['_id'], payload: trans, node_id: self.node_id, user: self.user, http_client: self.http_client)
      transaction
    end

    def get_all_transaction(**options)
      [options[:page], options[:per_page]].each do |arg|
        if arg && (!arg.is_a?(Integer) || arg < 1)
          raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
        end
      end

      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "/trans"

      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact

      path += '?' + params.join('&') if params.any?

      begin
        trans = http_client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        trans = http_client.get(path)
      end 

    
      response = trans["trans"].map { |trans_data| Transaction.new(trans_id: trans_data['_id'], payload: trans_data, node_id: self.node_id, user: self.user, http_client: self.http_client)}
      trans = Transactions.new(limit: trans["limit"], page: trans["page"], page_count: trans["page_count"], trans_count: trans["trans_count"], payload: response)
      trans
    end

    def verify_micro_deposit(payload:)
      path = nodes_path(user_id: self.user_id, node_id: self.node_id)
      begin
        response = http_client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        response = http_client.patch(path, payload)
      end 
      response
    end


    def reinitiate_micro_deposit()
      payload = {}
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "?resend_micro=YES"
      begin
        response = http_client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        response = http_client.patch(path, payload)
      end 
      response
    end

    def generate_apple_pay_token(payload:)
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "/applepay"
      begin
        response = http_client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        response = http_client.patch(path, payload)
      end 
      response
    end

    def update_node(payload:)
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) 

      if user == nil
        user = get_user(user_id: self.user_id)
      end
     
      begin
        update = http_client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        update = http_client.get(path)
      end 
      update = Node.new(node_id: self.node_id, 
                              user_id: self.user_id, 
                              http_client: http_client, 
                              payload: update, 
                              full_dehydrate: false,
                              user: user
                              )
    end

    def delete_node()
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) 
     
      if user == nil
        user = get_user(user_id: self.user_id)
      end

      begin
        delete = http_client.delete(path)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        delete = http_client.delete(path)
      end 
      delete
    end

    # Initiates dummy transactions to a node
    # @param is_credit [Boolean]
    def dummy_transactions(is_credit:nil)

      is_credit = "YES" if is_credit == true
      is_credit = "NO" if is_credit == false
      if is_credit  
        path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "/dummy-tran?#{is_credit}" 
      else
        path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "/dummy-tran" 
      end

      if user == nil
        user = get_user(user_id: self.user_id)
      end

      begin
       response = http_client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       response = http_client.get(path)
      end
      response
    end

    # Creates subnet for a node 
    # @param [Hash] 
    def create_subnet(payload:)
      path = subnet_path(user_id: self.user_id, node_id: self.node_id) 

      if user == nil
        user = get_user(user_id: self.user_id)
      end

      begin
       subnet = http_client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       subnet = http_client.post(path,payload)
      end
      subnet = Subnet.new(subnet_id: subnet['_id'], payload: subnet)
      subnet
    end


    # Gets all node subnets.
    # @param page [Integer]
    # @param per_page [Integer]  
    # @see https://docs.synapsefi.com/docs/all-node-subnets
    def get_all_subnets(**options)
      [options[:page], options[:per_page]].each do |arg|
        if arg && (!arg.is_a?(Integer) || arg < 1)
          raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
        end
      end

      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "/subnets"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact
      path += '?' + params.join('&') if params.any?

      if user == nil
        user = get_user(user_id: self.user_id)
      end

      begin
       subnets = http_client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       subnets = http_client.get(path)
      end

      response = subnets["subnets"].map { |subnets_data| Subnet.new(subnet_id: subnets_data['_id'], payload: subnets)}
      subnets = Subnets.new(limit: subnets["limit"], page: subnets["page"], page_count: subnets["page_count"], subnets_count: subnets["trans_count"], payload: response)
      subnets
    end

    def get_subnet(subnet_id:)
      if user == nil
        user = get_user(user_id: self.user_id)
      end

      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "/subnets/#{subnet_id}"

      begin
       subnet = http_client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       subnet = http_client.get(path)
      end
      subnet = Subnet.new(subnet_id: subnet['_id'], payload: subnet)
      subnet 
    end

    # Gets statement by node.
    # @param page [SynapsePayRest::Client]
    # @param per_page [SynapsePayRest::User]  
    # @see https://docs.synapsefi.com/docs/statements-by-user
    def get_statements(**options)
      [options[:page], options[:per_page]].each do |arg|
        if arg && (!arg.is_a?(Integer) || arg < 1)
          raise ArgumentError, "#{arg} must be nil or an Integer >= 1"
        end
      end
      
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "/statements"
      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact
      path += '?' + params.join('&') if params.any?

      begin
       statements = http_client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       user.authenticate()
       statements = http_client.get(path)
      end

      statements
    end


    private
    def nodes_path(user_id:, node_id:)
      path = "/users/#{user_id}/nodes/#{node_id}"
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

    def get_user(user_id:)
      response = http_client.get("/users/#{user_id}")
      user = User.new(
            user_id:                response['_id'],
            refresh_token:     response['refresh_token'],
            client:            http_client,
            full_dehydrate:    false,
            payload:           response
          )
      user
    end
	end
end


