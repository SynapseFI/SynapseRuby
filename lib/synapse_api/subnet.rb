module Synapse

  class Subnet

    attr_accessor  :subnet_id, :payload

    def initialize(subnet_id:, payload:, node_id:)
      @subnet_id = subnet_id
      @payload = payload
      @node_id = node_id
    end
  end
end
