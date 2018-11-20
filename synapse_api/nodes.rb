require_relative './http_request'

module SynapsePayRest

	class Nodes

		attr_reader :page, :page_count, :limit, :http_client, :payload, :user_count

		attr_accessor 

		def initialize(page:,limit:, page_count:, node_count:, payload:,http_client:)
			@page = page 
			@limit = limit
			@http_client = http_client
			@node_count = node_count
			@page_count = page_count
			@payload = payload
		end
	end
end


