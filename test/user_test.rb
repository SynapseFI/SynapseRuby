require 'minitest/autorun'
require 'minitest/reporters'
require '../synapse_api/client'
require 'pp'

class UserTest < Minitest::Test
  
  def setup
    @options = {
      client_id:       'client_id_IvSkbeOZAJlmM4ay81EQC0oD7WnP6X9UtRhKs5Yz',
      client_secret:    'client_secret_1QFnWfLBi02r5yAKhovw8Rq9MNPgCkZE4ulHxdT0',
      ip_address:       '127.0.0.1',
      fingerprint:      'static_pin',
      development_mode: true,
      base_url: 'https://uat-api.synapsefi.com/v3.1'
    }
    #client = SynapsePayRest::Client.new(@options)
    #user = "5bd9e16314c7fa00a3076960"
    #user = client.get_user(user_id: user)
  end

  def test_user_update
    client = SynapsePayRest::Client.new(@options)
    user = "5bfda38abaabfc00b0700187"
    user = client.get_user(user_id: user)
    payload = {
      "update":{
        "login":{
          "email":"andrew@synapsefi.com"
        },
        "remove_login":{
          "email":"test@synapsefi.com"
        }
      }
    }

    response = user.user_update(payload: payload)
    
    assert_includes response["logins"][0]["email"], payload[:update][:login][:email]
  end

  def test_get_transactions
    client = SynapsePayRest::Client.new(@options)
    user = "5bd9e16314c7fa00a3076960"
    user = client.get_user(user_id: user)
    transactions = user.get_transactions()

    assert_instance_of SynapsePayRest::Transactions, transactions
  end

  def test_get_all_nodes
    client = SynapsePayRest::Client.new(@options)
    user = "5bd9e16314c7fa00a3076960"
    user = client.get_user(user_id: user)

    nodes = user.get_all_nodes(type:"ACH-US")
    assert_equal 3, nodes.nodes_count 
    assert_equal nodes.payload[0].payload["type"], "ACH-US"
  end

  def test_get_node
    client = SynapsePayRest::Client.new(@options)
    user = "5bd9e16314c7fa00a3076960"
    user = client.get_user(user_id: user)
    node = user.get_node(node_id: "5bfed4e8bab475008ea4e390", full_dehydrate: true)
    
    assert_equal true, node.full_dehydrate 
  end

  def test_get_statements
    client = SynapsePayRest::Client.new(@options)
    user = "5bd9e16314c7fa00a3076960"
    user = client.get_user(user_id: user)
    statements = user.get_statements()

    assert_equal "200", statements["http_code"]
  end

end
