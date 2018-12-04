require './synapse_api/client'
require 'json'
require 'pp'
# hash (object)
args = {
	client_id:        "client_id_IvSkbeOZAJlmM4ay81EQC0oD7WnP6X9UtRhKs5Yz",
	client_secret:    "client_secret_1QFnWfLBi02r5yAKhovw8Rq9MNPgCkZE4ulHxdT0",
	fingerprint:      "static_pin",
	ip_address:       '127.0.0.1',
	development_mode: true
}

args = args


puts "========Client Object Created==========" 

client  = SynapsePayRest::Client.new(args) 
pp client 

puts "=======Creates a User===========" 


args = {
  "logins": [
    {
      "email": "test@synapsefi.com"
    }
  ],
  "phone_numbers": [
    "901.111.1111",
    "test@synapsefi.com"
  ],
  "legal_names": [
    "Andrew Martin"
  ]
}



user = client.create_user(payload: args) 
puts user.user_id
pp user 

puts "========Add User Docs=========="
args = {
  "documents":[{
        "email":"test@test.com",
        "phone_number":"901.111.1111",
        "ip":"::1",
        "name":"Andrew Martin",
        "alias":"Test",
        "entity_type":"M",
        "entity_scope":"Arts & Entertainment",
        "day":2,
        "month":5,
        "year":1989,
        "address_street":"1 Market St.",
        "address_city":"San Francisco",
        "address_subdivision":"CA",
        "address_postal_code":"94114",
        "address_country_code":"US",
        "virtual_docs":[{
            "document_value":"2222",
            "document_type":"SSN"
        }],
        "physical_docs":[{
            "document_value": "data:image/gif;base64,SUQs==",
            "document_type": "GOVT_ID"
        }],
        "social_docs":[{
            "document_value":"https://www.facebook.com/valid",
            "document_type":"FACEBOOK"
        }]
    }]}

 user = user.add_base_doc(payload: args)
 pp user 

raise 


puts "========Gets a User=========="


user = "5bea4453321f48299bac84e8"
user = client.get_user(user_id: user,full_dehydrate: true)
pp user 

puts "========Gets All Users========="

pp client.get_users

puts "=========Gets All Transactions========="

pp client.get_transaction

puts "=========Gets All User Transactions specific to a user (Needs OAUTH KEY)========="

user_id = "5bd9e16314c7fa00a3076960"
# add pagination to transactions querry
pp client.get_transactions(user_id)

puts "=========Gets All Nodes========="
# add pagination to transactions querry
pp client.get_all_nodes

puts "=========Create Subscriptions========="
#puts client.create_subscriptions(payload)
pp client.create_subscriptions(scope: ["TRAN|PATCH"], url: "https://webhook.site/155f30bc-0c1a-42b9-b075-12c18fd242c5")

puts "=========Gets All Subscriptions========="

pp client.get_all_subscriptions()

puts "=========Gets a Subscription========="

subscriptions_id = "5beb6f2fbddf603229fe4ec5"
puts client.get_subscription(subscriptions_id)

puts "========Update Subscription=========="

subscription_id = "5beb6f2fbddf603229fe4ec5"

puts client.update_subscriptions(subscription_id: subscription_id ,scope: ["USERS|POST", "USER|PATCH", "NODES|POST"])

puts "========Issue Public Key=========="

puts client.issue_public_key(scope:"OAUTH|POST,USERS|POST,USERS|GET,USER|GET,USER|PATCH")

puts "========Dummy Transactions=========="

#node and has to belong to user 
user_id = "5be2427dea4d4b6a8bf95b71"
node_id = "5be24283389f247ab2b05842"

puts client.dummy_transactions(user_id: user_id,node_id: node_id)

puts "========Change Scope=========="

user = "5bea4453321f48299bac84e8"
scope =["TRAN|PATCH"]

scope = client.change_user_scope(user_id: user, scope: scope )

puts "=========Get Transaction========="

node_id = "5bd9e7b3389f2400adb012ae"
trans_id = "5bd9ee3874dcec00d4a8864f"

trans = user.get_transaction(node_id: node_id,trans_id: trans_id)

puts trans 

puts "=========Delete Transaction========="

node_id = "5bd9e7b3389f2400adb012ae"
trans_id = "5bfec645bab8f200d4e85fbd"

#delete = user.cancel_transaction(node_id: node_id,trans_id: trans_id)

#puts delete

puts "=========Comment on Delete Transaction========="

node_id = "5bd9e7b3389f2400adb012ae"
trans_id = "5bfec645bab8f200d4e85fbd"
payload = {
  "comment": "I deleted this transaction"
}

transaction = user.comment_transaction(node_id: node_id,trans_id: trans_id, payload: payload)

pp transaction 

puts "========Get Node ==========" 
node_id = "5bd9e7b3389f2400adb012ae"

pp user.get_node(node_id: node_id, full_dehydrate: true, force_refresh: true)

puts "========Create Card-US Node ==========" 
payload = {
  "type": "CARD-US",
  "info": {
    "nickname":"My Debit Card",
    "document_id":"6edbf71154676e17febe0d5d01d25c5a1349c1c482ed25eb23612e4b82e8ca9f"
  }
}

pp user.create_card_us_node(payload: payload)

puts "========Ship Card-US Node ==========" 
payload = {
  "fee_node_id":"5bef0dbdb95dfb00bfdc2473",
  "expedite":true
}
ship = node.ship_card(payload:payload)
puts ship

puts "========Get Transaction ==========" 
trans_id = "5bd9ee3874dcec00d4a8864f"

puts node.get_transaction(trans_id: trans_id)

puts "========Create Transaction ==========" 

payload = {
  "to": {
    "type": "SYNAPSE-US",
    "id": "55b3f8c686c2732b4c4e9df6"
  },
  "amount": {
    "amount": 20.1,
    "currency": "USD"
  },
  "extra": {
    "ip": "192.168.0.1"
  }
}

puts node.create_transaction(payload: payload)

puts "========Create Subnet==========" 

payload = {
  "nickname":"Test AC/RT"
}

pp node.create_subnet(payload: payload)

args = {
  client_id:        "client_id_IvSkbeOZAJlmM4ay81EQC0oD7WnP6X9UtRhKs5Yz",
  client_secret:    "client_secret_1QFnWfLBi02r5yAKhovw8Rq9MNPgCkZE4ulHxdT0",
  fingerprint:      "static_pin",
  ip_address:       '127.0.0.1',
  development_mode: true
}

args = args


puts "========Client Object Created==========" 

client  = SynapsePayRest::Client.new(args) 

puts "========Gets a User=========="


user = "5bd9e16314c7fa00a3076960"
user = client.get_user(user_id: user,full_dehydrate: true)

puts "========Get Node ==========" 
node_id = "5bd9e7b3389f2400adb012ae"

node = user.get_node(node_id: node_id, full_dehydrate: true, force_refresh: true)

puts "========Create Subnet==========" 

payload = {
  "nickname":"Test AC/RT"
}

pp node.create_subnet(payload: payload)






















    def create_deposit_us(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response,
        user: self
        )
      node
    end

    def create_ach_us_logins(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response,
        user: self
        )
      node
    end

     def create_ach_us_mfa(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response,
        user: self
        )
      node
    end

    def create_ach_us_act_rt(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response,
        user: self
        )
      node
    end

    def create_interchange_us(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response,
        user: self
        )
      node
    end

    def create_check_us(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response,
        user: self
        )
      node
    end

    def create_crypto_us(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response,
        user: self
        )
      node
    end

    def create_wire_us(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response,
        user: self
        )
      node
    end

    def create_wire_int(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response,
        user: self
        )
      node
    end

    def create_iou(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response,
        user: self
        )
      node
    end

    def create_loan(payload:)
      path = get_user_path(user_id: self.user_id)
      path = path + nodes_path
  
      begin
       response = client.post(path,payload)
      rescue SynapsePayRest::Error::Unauthorized
       self.authenticate()
       response = client.post(path,payload)
      end

      
      node = Node.new(
        user_id: self.user_id,
        node_id: response["nodes"][0]["_id"],
        full_dehydrate: false,
        http_client: client, 
        payload: response,
        user: self
        )
      node
    end

















