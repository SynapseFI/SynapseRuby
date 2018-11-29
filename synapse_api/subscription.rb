require_relative './http_request'

module SynapsePayRest

	class Subscription

		attr_reader :subscription_id, :url, :payload

		attr_accessor 

		def initialize(subscription_id:, url:, payload:, http_client:)
			@subscription_id = subscription_id
			@url = url
			@http_client = http_client

		end

    # TODO
    # Updates the given key value pairs [is_active, url, scope]
    # see https://docs.synapsefi.com/docs/update-subscription
    # @param is_active [boolean]
    # @param url [String]
    # @param scope [Array<String>]
    # @return [SynapsePayRest::Subscription] new instance corresponding to same API record
    def update_subscriptions(subscription_id:, url:nil, scope:nil)
      raise ArgumentError, 'client must be a SynapsePayRest::Client' unless self.is_a?(Client)
      raise ArgumentError, 'scope must be an array' unless options[:scope].is_a?(Array)
      path = subscriptions_path + "/#{subscription_id}"

    
      payload = {}

      payload["url"] = url if url
      payload["scope"] = scope if scope

      response = client.patch(path, payload)
      subscriptions = Subscription.new(subscription_id: response["_id"], url: response["url"], http_client: client, payload: response)
    end

	end
end
