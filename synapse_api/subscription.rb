require_relative './http_request'

module SynapsePayRest

	class Subscription

		attr_reader :subscription_id, :url, :payload

		attr_accessor 

		def initialize(subscription_id:, url:, payload:, http_client:)
			@subscription_id = subscription_id
			@url = url
			@http_client = http_client

		end
	end
end
