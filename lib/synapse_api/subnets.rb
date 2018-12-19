module Synapse

  class Subnets

    attr_accessor  :page, :page_count, :limit, :payload, :subnets_count, :node_id

    def initialize(limit:, page:, page_count:, subnets_count:, payload:, node_id:)
      @page = page
      @limit = limit
      @subnets_count = subnets_count
      @payload = payload
      @page_count = page_count
      @node_id = node_id
    end
  end
end
