module Synapse

	class Subscription

		attr_reader :subscription_id, :url, :payload

		attr_accessor

		def initialize(subscription_id:, url:, payload:)
			@subscription_id = subscription_id
			@url = url
      @payload = payload
		end
	end
end
