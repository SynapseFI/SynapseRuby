# frozen_string_literal: true

require 'test_helper'

class UserTest < Minitest::Test
  def setup
    @options = {
      client_id: ENV.fetch('TEST_CLIENT_ID'),
      client_secret: ENV.fetch('TEST_CLIENT_SECRET'),
      ip_address: '127.0.0.1',
      fingerprint: 'static_pin',
      development_mode: true,
      base_url: 'https://uat-api.synapsefi.com/v3.1'
    }
    # please make sure to change constant with your own values
    @user_id = '643818d73fe5ad4cb89e918c'
    @card = '64381ee7cce5141d978484bd'
    @card_trans_id = '643829b3256b9bb51db73ad8'
    @card_fee_node = '5bd9e7b3389f2400adb012ae'
    @deposit = '55b3f8c686c2732b4c4e9df6'
    @deposit_trans_id = '64381e4e57d9484173cd23cb'
    @deposit_subnet_id = '64382965ba34d6ded28e5339'
    @synapse_account = '55b3f8c686c2732b4c4e9df6'
    @subnet_card = '643820276b4def244ed6c575'
    @subnet_id = '643824d9bff1c2f558ad1c7b'
  end

  def test_user_update
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    payload = {
      "update": {
        "login": {
          "email": 'andrew@synapsefi.com'
        },
        "remove_login": {
          "email": 'test@synapsefi.com'
        }
      }
    }

    response = user.user_update(payload: payload)

    refute_match response.payload['logins'][0]['email'], payload[:update][:login][:email]
  end

  def test_get_all_user_transaction
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    transactions = user.get_user_transactions

    assert_instance_of Synapse::Transactions, transactions
  end

  def test_get_all_user_nodes
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)

    nodes = user.get_all_user_nodes(type: 'ACH-US')
    assert_equal nodes.payload[0].payload['type'], 'ACH-US'
  end

  def test_get_user_node
    client = Synapse::Client.new(**@options)
    user = @user_id
    node = @card
    user = client.get_user(user_id: user)
    node = user.get_user_node(node_id: node, full_dehydrate: true)

    assert_equal true, node.full_dehydrate
  end

  def test_get_statements
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    statements = user.get_user_statement

    assert_equal '200', statements['http_code']
  end

  def test_create_transaction
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)

    node_id = @card
    account = @synapse_account
    payload = {
      "to": {
        "type": 'SYNAPSE-US',
        "id": account
      },
      "amount": {
        "amount": 20.1,
        "currency": 'USD'
      },
      "extra": {
        "ip": '192.168.0.1'
      }
    }
    transaction = user.create_transaction(node_id: node_id, payload: payload)

    assert_instance_of Synapse::Transaction, transaction
  end

  def test_get_node_transaction
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = @card
    trans_id = @card_trans_id

    transaction = user.get_node_transaction(node_id: node_id, trans_id: trans_id)

    assert_instance_of Synapse::Transaction, transaction
  end

  def test_get_all_node_transaction
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = @deposit

    transactions = user.get_all_node_transaction(node_id: node_id)

    assert_instance_of Synapse::Transactions, transactions
  end

  def test_dummy_transactions
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = @card
    transaction = user.dummy_transactions(node_id: node_id, is_credit: 'YES')
    assert_equal transaction['success'], true
  end

  def test_create_subnet
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = @deposit
    payload = {
      "nickname": 'Test AC/RT'
    }

    subnet = user.create_subnet(node_id: node_id, payload: payload)
    assert_instance_of Synapse::Subnet, subnet
  end

  def test_get_all_subnets
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = @deposit
    subnets = user.get_all_subnets(node_id: node_id)
    assert_instance_of Synapse::Subnets, subnets
  end

  def test_get_subnet
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = @deposit
    subnet_id = @deposit_subnet_id

    subnets = user.get_subnet(node_id: node_id, subnet_id: subnet_id)
    assert_instance_of Synapse::Subnet, subnets
  end

  def test_get_node_statements
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = @deposit

    statements = user.get_node_statements(node_id: node_id)
    assert_equal '200', statements['http_code']
  end

  def test_comment_transaction
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = @deposit
    trans_id = @deposit_trans_id

    payload = {
      "comment": 'It Settled!'
    }

    transaction = user.comment_transaction(node_id: node_id, trans_id: trans_id, payload: payload)
    assert_instance_of Synapse::Transaction, transaction
  end

  def test_update_node
    client = Synapse::Client.new(**@options)
    user = '643816d2689e037e848106e9'
    user = client.get_user(user_id: user)
    node_id = @deposit
    payload = {
      "nickname": 'Savings'
    }

    node = user.update_node(node_id: node_id, payload: payload)

    assert_equal node_id, node.node_id
  end

  def test_update_subnet
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = @subnet_card
    subnet_id = @subnet_id
    body = {
      "preferences": {
        "allow_foreign_transactions": true,
        "daily_atm_withdrawal_limit": 100,
        "daily_transaction_limit": 900
      }
    }

    subnet = user.update_subnet(node_id: node_id, payload: body, subnet_id: subnet_id)

    assert_equal node_id, subnet.node_id
  end

  def test_ship_card_node
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = @card
    fee_node = @card_fee_node
    payload = {
      "fee_node_id": fee_node,
      "expedite": false
    }

    ship = user.ship_card_node(node_id: node_id, payload: payload)

    assert_equal node_id, ship.node_id
  end

  def test_reset_card_node
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    node_id = @card

    reset = user.reset_card_node(node_id: node_id)

    assert_equal node_id, reset.node_id
  end

  def test_create_node
    client = Synapse::Client.new(**@options)
    user = @user_id
    user = client.get_user(user_id: user)
    payload = {
      "type": 'IB-DEPOSIT-US',
      "info": {
        "nickname": 'My Deposit Account'
      }
    }
    node = user.create_node(payload: payload)
    assert_equal 1, node.nodes_count
  end
end
