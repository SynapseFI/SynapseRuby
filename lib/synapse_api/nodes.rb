# frozen_string_literal: true

module Synapse
  class Nodes
    attr_reader :page, :page_count, :limit, :payload, :nodes_count

    attr_accessor

    def initialize(page:, limit:, page_count:, nodes_count:, payload:)
      @page = page
      @limit = limit
      @nodes_count = nodes_count
      @page_count = page_count
      @payload = payload
    end
  end
end
