require_relative './http_request'

module SynapsePayRest

	class Subscriptions

		attr_reader :subscriptions_count, :url, :http_client

		attr_accessor 

		def initialize(page:,limit:, subscriptions_count:, payload:, http_client:,page_count:)
			@subscriptions_count = subscriptions_count
			@http_client = http_client
		end
	end
end
