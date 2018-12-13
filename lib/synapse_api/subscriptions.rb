require_relative './http_request'

module SynapsePayRest

	class Subscriptions

		attr_reader :subscriptions_count, :page, :limit, :payload, :page_count

		attr_accessor

		def initialize(page:,limit:, subscriptions_count:, payload:, page_count:)
			@subscriptions_count = subscriptions_count
			@page = page
      @limit = limit
      @payload = payload
      @page_count = page_count
		end
	end
end
