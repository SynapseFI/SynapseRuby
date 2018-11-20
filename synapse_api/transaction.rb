require_relative './http_request'

module SynapsePayRest

	class Transaction

		
		attr_accessor  :trans_id, :user_id, :node_id, :http_client, :payload

		def initialize(trans_id:, http_client:, payload:)
			@http_client = http_client
			@trans_id = trans_id 
			@user_id = user_id
			@node_id = node_id
			@payload = payload
		end
	end
end

