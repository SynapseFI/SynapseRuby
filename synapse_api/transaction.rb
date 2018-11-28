require_relative './http_request'

module SynapsePayRest

	class Transaction

		
		attr_accessor  :trans_id, :payload

		def initialize(trans_id:, payload:)
			@trans_id = trans_id 
			@payload = payload
		end
	end
end

