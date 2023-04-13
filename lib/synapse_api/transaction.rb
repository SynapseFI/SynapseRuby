# frozen_string_literal: true

module Synapse
  class Transaction
    attr_accessor :trans_id, :payload, :node_id, :user

    def initialize(trans_id:, payload:, node_id: nil, user: nil)
      @trans_id = trans_id
      @payload = payload
      @node_id = node_id
      @user = user
    end
  end
end
