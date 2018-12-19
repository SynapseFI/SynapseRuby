module Synapse

	class Transactions

		attr_reader :page, :page_count, :limit, :payload, :trans_count

		attr_accessor

		def initialize(page:,limit:, trans_count:, payload:, page_count:)
			@page = page
			@limit = limit
			@trans_count = trans_count
			@payload = payload
      @page_count = page_count
		end
	end
end


