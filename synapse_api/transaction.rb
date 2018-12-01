require_relative './http_request'

module SynapsePayRest

	class Transaction

		
		attr_accessor  :trans_id, :payload, :node_id, :user 

		def initialize(trans_id:, payload:, node_id:, user:)
			@trans_id = trans_id 
			@payload = payload
      @node_id = node_id
      @user = user
		end

    # Adds a comment to the transaction's timeline/recent_status fields
    # @param payload: [String]
    def comment_transaction(payload:)
      user_id = user.user_id
      path = "/users/#{user_id}/nodes/#{self.node_id}/trans/#{self.trans_id}" 
      begin
        trans = client.patch(path, payload)
      rescue SynapsePayRest::Error::Unauthorized
        self.authenticate()
        trans = client.patch(path, payload)
      end 
      transaction = Transaction.new(trans_id: trans['_id'], payload: trans)
      transaction
    end

    # Cancels this transaction if it has not already settled
    def cancel_transaction()
      user_id = user.user_id
      path = "/users/#{user_id}/nodes/#{self.node_id}/trans/#{self.trans_id}" 
      begin
        response = client.delete(path)
      rescue SynapsePayRest::Error::Unauthorized
        self.authenticate()
        response = client.delete(path)
      end 
      response
    end
	end
end

