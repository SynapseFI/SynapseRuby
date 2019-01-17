require "test_helper.rb"

class UserTest < Minitest::Test

  def setup
    @options = {
      client_id:       ENV.fetch('TEST_CLIENT_ID'),
      client_secret:    ENV.fetch('TEST_CLIENT_SECRET'),
      ip_address:       '127.0.0.1',
      fingerprint:      'static_pin',
      development_mode: true,
      base_url: 'https://uat-api.synapsefi.com/v3.1'
    }
    # please make sure to change constant with your own user_id
    @user_id ="5bd9e16314c7fa00a3076960"
  end

  def test_user_update
    client = Synapse::Client.new(@options)
    user = @user_id
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

    refute_match response.payload["logins"][0]["email"], payload[:update][:login][:email]
  end

  def test_get_all_user_transaction
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    transactions = user.get_user_transactions()

    assert_instance_of Synapse::Transactions, transactions
  end

  def test_get_all_user_nodes
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)

    nodes = user.get_all_user_nodes(type:"ACH-US")
    assert_equal nodes.payload[0].payload["type"], "ACH-US"
  end

  def test_get_user_node
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node = user.get_user_node(node_id: "5bfed4e8bab475008ea4e390", full_dehydrate: true)

    assert_equal true, node.full_dehydrate
  end

  def test_get_statements
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    statements = user.get_user_statement()

    assert_equal "200", statements["http_code"]
  end

  def test_create_transaction
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)

    node_id = "5bd9ebfe389f2400afb03a97"
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
    transaction = user.create_transaction(node_id: node_id, payload: payload)

    assert_instance_of Synapse::Transaction, transaction
  end

  def test_get_node_transaction
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = "5bfed4e8bab475008ea4e390"
    trans_id = "5c002ab7c9ab5b00ea5a8abd"

    transaction = user.get_node_transaction(node_id: node_id, trans_id: trans_id)

    assert_instance_of Synapse::Transaction, transaction
  end

  def test_get_all_node_transaction
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = "5bd9f755389f2400b9b0a25f"

    transactions = user.get_all_node_transaction(node_id: node_id)

    assert_instance_of Synapse::Transactions, transactions
  end

  def test_dummy_transactions
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = "5bd9f755389f2400b9b0a25f"
    transaction = user.dummy_transactions(node_id: node_id, is_credit: true)
    assert_equal transaction["success"], true
  end

  def test_create_subnet
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = "5bd9ebfe389f2400afb03a97"
    payload = {
      "nickname":"Test AC/RT"
    }

    subnet = user.create_subnet(node_id: node_id, payload: payload)
    assert_instance_of Synapse::Subnet, subnet
  end

  def test_get_all_subnets
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = "5bd9f755389f2400b9b0a25f"
    subnets = user.get_all_subnets(node_id: node_id)
    assert_instance_of Synapse::Subnets, subnets
  end

  def test_get_subnet
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = "5bd9f755389f2400b9b0a25f"
    subnet_id = "5c002eb460128b001f217787"

    subnets = user.get_subnet(node_id: node_id, subnet_id: subnet_id)
    assert_instance_of Synapse::Subnet, subnets
  end

  def test_get_node_statements
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = "5bd9f755389f2400b9b0a25f"


    statements = user.get_node_statements(node_id: node_id)
    assert_equal "200", statements["http_code"]
  end

  def test_comment_transaction
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = "5bd9f755389f2400b9b0a25f"
    trans_id = "5c087d9699c81e5b3328e860"

    payload = {
      "comment": "It Settled!"
    }

    transaction = user.comment_transaction(node_id: node_id, trans_id: trans_id, payload: payload)
    assert_instance_of Synapse::Transaction, transaction
  end

  def test_update_node
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = "5bd9f755389f2400b9b0a25f"
    payload = {
      "nickname": "Savings"
    }

    node = user.update_node(node_id: node_id, payload: payload)

    assert_equal node_id,  node.node_id
  end

  def test_ship_card
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = "5bfed4e8bab475008ea4e390"
    payload = {
      "fee_node_id":"5bd9e7b3389f2400adb012ae",
      "expedite":false
    }

    ship = user.ship_card(node_id: node_id, payload: payload)

    assert_equal node_id,  ship.node_id
  end

  def test_reset_debit_card
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = "5bfed4e8bab475008ea4e390"


    reset = user.reset_debit_card(node_id: node_id)

    assert_equal node_id,  reset.node_id
  end


  def test_create_node
    client = Synapse::Client.new(@options)
    user = @user_id
    user = client.get_user(user_id: user)
    payload = {
      "type": "IB-DEPOSIT-US",
      "info": {
        "nickname":"My Deposit Account"
      }
    }
    node = user.create_node(payload: payload)
    assert_equal 1, node.nodes_count
  end
end
