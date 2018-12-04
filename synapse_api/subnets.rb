module SynapsePayRest

  class Subnets

    attr_accessor  :page, :page_count, :limit, :payload, :subnets_count

    def initialize(limit:, page:, page_count:, subnets_count:, payload:)
      @page = page 
      @limit = limit
      @subnets_count = subnets_count
      @payload = payload
      @page_count = page_count
    end
  end
end