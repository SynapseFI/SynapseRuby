require_relative './http_request'

module SynapsePayRest

	class Node


		attr_reader :node_id, :user_id, :payload, :full_dehydrate, :http_client

		attr_accessor 

		def initialize(node_id:, user_id:,payload:, full_dehydrate:, http_client:)
			@node_id = node_id
			@full_dehydrate = full_dehydrate
			@http_client = http_client
			@user_id = user_id 
			@payload = payload
		end

    def ship_card(payload:)
    
      path = nodes_path(user_id: self.user_id) + "?ship=YES"
      
      begin
       response = http_client.patch(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = http_client.patch(path,payload)
      end
      response
    end

    def reset_debit_card(payload:)
      path = nodes_path(user_id: self.user_id) + "?reset=YES"
  
      begin
       response = http_client.patch(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = http_client.patch(path,payload)
      end
      response
    end

    private
    def nodes_path(user_id:,**options)
      path = "/users/#{user_id}/nodes/#{node_id}"
      path
    end

	end
end


