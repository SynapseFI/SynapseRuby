require_relative './http_request'

module SynapsePayRest

	class Transaction

		
		attr_accessor  :trans_id, :payload, :node_id, :user, :http_client 

		def initialize(trans_id:, payload:, node_id:nil, user:nil, http_client:)
			@trans_id = trans_id 
			@payload = payload
      @node_id = node_id
      @user = user
		end

    # Adds a comment to the transaction's timeline/recent_status fields
    # @param payload: [String]
    def comment_transaction(payload:)
      user_id = user.user_id
      path = trans_path(user_id: user_id, node_id: self.node_id, trans_id: self.trans_id)

      begin
        trans = http_client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        trans = http_client.patch(path, payload)
      end 
      transaction = Transaction.new(trans_id: trans['_id'], payload: trans)
      transaction
    end

    # Cancels this transaction if it has not already settled
    def cancel_transaction()
      user_id = user.user_id
      path = trans_path(user_id: user_id, node_id: self.node_id, trans_id: self.trans_id)
      begin
        response = http_client.delete(path)
      rescue SynapsePayRest::Error::Unauthorized
        user.authenticate()
        response = http_client.delete(path)
      end 
      response
    end

    private

    def trans_path(user_id:,node_id:,trans_id:)
      path = "/users/#{user_id}/nodes/#{node_id}/trans/#{trans_id}" 
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

