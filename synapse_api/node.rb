require_relative './http_request'

module SynapsePayRest

	class Node

		attr_reader :node_id, :user_id, :payload, :full_dehydrate

		attr_accessor 

		def initialize(node_id:, user_id:,payload:, full_dehydrate:, http_client:)
			@node_id = node_id
			@full_dehydrate = full_dehydrate
			@http_client = http_client
			@user_id = user_id 
			@payload = payload
		end
	end
end


