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
    "Test User"
  ],
  "extra": {
    "supp_id": "122eddfgbeafrfvbbb",
    "cip_tag":1,
    "is_business": false
  }
}



user = client.create_user(payload: args) 
pp user 


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










