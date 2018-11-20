require_relative './http_request'

module SynapsePayRest

	class Transactions

		attr_reader :page, :page_count, :limit, :http_client, :payload, :trans_count

		attr_accessor 

		def initialize(page:,limit:, trans_count:, payload:, http_client:,page_count:)
			@page = page 
			@limit = limit
			@trans_count = trans_count
			@payload = payload
		end
	end
end


