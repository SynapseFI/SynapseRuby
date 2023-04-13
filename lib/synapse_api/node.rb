# frozen_string_literal: true

module Synapse
  class Node
    attr_reader :node_id, :user_id, :payload, :full_dehydrate, :type

    attr_accessor

    def initialize(node_id:, user_id:, payload:, full_dehydrate:, type: nil)
      @node_id = node_id
      @full_dehydrate = full_dehydrate
      @user_id = user_id
      @payload = payload
      @type = type
    end
  end
end
