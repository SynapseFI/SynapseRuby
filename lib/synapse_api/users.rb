module Synapse

	class Users

		attr_reader :page, :page_count, :limit, :http_client,:payload, :user_count

		attr_accessor

		def initialize(page:, page_count:, limit:, http_client:,payload:, user_count:)
			@http_client = http_client
			@page = page
			@page_count = page_count
			@limit =limit
			@user_count = user_count
			@payload = payload
		end
	end
end


