module SynapsePayRest

	class Node

    # valid query params 
    VALID_QUERY_PARAMS = [:page, :per_page].freeze

		attr_reader :node_id, :user_id, :payload, :full_dehydrate, :http_client

		attr_accessor 

		def initialize(node_id:, user_id:,payload:, full_dehydrate:, http_client:)
			@node_id = node_id
			@full_dehydrate = full_dehydrate
			@http_client = http_client
			@user_id = user_id 
			@payload = payload
		end

    def ship_card(payload:)
    
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "?ship=YES"
      
      begin
       response = http_client.patch(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       http_client.oauthenticate(user_id: self.user_id)
       response = http_client.patch(path,payload)
      end
      response
    end

    def reset_debit_card(payload:)
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "?reset=YES"
  
      begin
       response = http_client.patch(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       http_client.oauthenticate(user_id: self.user_id)
       response = http_client.patch(path,payload)
      end
      response
    end

    def create_transaction(payload:)
      path = trans_path(user_id: self.user_id, node_id: self.node_id)

      begin
       transaction = http_client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       http_client.oauthenticate(user_id: self.user_id)
       transaction = http_client.post(path,payload)
      end
      transaction = Transaction.new(trans_id: transaction['_id'], payload: transaction)
    end

    def get_transaction(trans_id:)
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "/trans/#{trans_id}" 
     
      begin
        trans = http_client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
        http_client.oauthenticate(user_id: self.user_id)
        trans = http_client.get(path)
      end 
      transaction = Transaction.new(trans_id: trans['_id'], payload: trans)
      transaction
    end

    def get_all_transaction(**options)
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) + "/trans"

      params = VALID_QUERY_PARAMS.map do |p|
        options[p] ? "#{p}=#{options[p]}" : nil
      end.compact

      path += '?' + params.join('&') if params.any?

      begin
        trans = http_client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
        http_client.oauthenticate(user_id: self.user_id)
        trans = http_client.get(path)
      end 

      return [] if trans["trans"].empty?
      response = trans["trans"].map { |trans_data| Transaction.new(trans_id: trans_data['_id'], payload: trans_data)}
      trans = Transactions.new(limit: trans["limit"], page: trans["page"], page_count: trans["page_count"], trans_count: trans["trans_count"], payload: response)
      trans
    end

    def update_node(payload:)
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) 
     
      begin
        update = http_client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
        http_client.oauthenticate(user_id: self.user_id)
        update = http_client.get(path)
      end 
      update = Transaction.new(trans_id: update['_id'], payload: update)
      update
    end

    def delete_node()
      path = nodes_path(user_id: self.user_id, node_id: self.node_id) 
     
      begin
        delete = http_client.delete(path)
      rescue SynapsePayRest::Error::Unauthorized
        http_client.oauthenticate(user_id: self.user_id)
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
      begin
       response = http_client.get(path)
      rescue SynapsePayRest::Error::Unauthorized
       http_client.oauthenticate(user_id: self.user_id)
       response = http_client.get(path)
      end
      response
    end

    # Creates subnet for a node 
    # @param [Hash] 
    def create_subnet(payload:)
      path = subnet_path(user_id: self.user_id, node_id: self.node_id) 

      begin
       subnet = http_client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       http_client.oauthenticate(user_id: self.user_id)
       subnet = http_client.post(path,payload)
      end
      subnet = Subnet.new(subnet_id: subnet['_id'], payload: subnet)
      subnet
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
	end
end


