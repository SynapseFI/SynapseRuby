# frozen_string_literal: true

require 'test_helper'

class ClientTest < Minitest::Test
  def setup
    # make sure to set up a .env file and add your own
    #  client_id and client_secret values
    @options = {
      client_id: ENV.fetch('TEST_CLIENT_ID'),
      client_secret: ENV.fetch('TEST_CLIENT_SECRET'),
      ip_address: '127.0.0.1',
      fingerprint: 'static_pin',
      development_mode: true
    }
    # please make sure to change constant with your own values
    @subscription = '5beb6f2fbddf603229fe4ec5'
  end

  # Testing HTTP_REQUEST @congfig through client class
  # Testing HTTP_REQUEST @base_url through client class
  def test_configured_through_options
    client = Synapse::Client.new(@options)
    # these keys don't exist in config
    @options.delete(:development_mode)
    @options[:oauth_key] = ''
    assert_equal client.client.config, @options
    assert_equal client.client.base_url, 'https://uat-api.synapsefi.com/v3.1'
  end

  # Test @base_url when development_mode is false
  def test_endpoint_changes_when_development_mode_false
    @options[:development_mode] = false
    client = Synapse::Client.new(@options)
    assert_equal client.client.base_url, 'https://api.synapsefi.com/v3.1'
  end

  # Test if client.client is and instance of HTTPClient
  def test_instance_reader_methods
    client = Synapse::Client.new(@options)
    # fails if HTTP::CLient is not an instance of the Client class
    assert_instance_of Synapse::HTTPClient, client.client
  end

  # test whether created user is an instance of Synapse::User
  def test_create_user
    client = Synapse::Client.new(@options)
    payload = {
      "logins": [
        {
          "email": 'test234@synapsefi.com'
        }
      ],
      "phone_numbers": [
        '921.221.3411',
        'test234@synapsefi.com'
      ],
      "legal_names": [
        'Andrew J'
      ]
    }
    @response = client.create_user(payload: payload, ip_address: '127.0.0.1')
    assert_instance_of Synapse::User, @response
  end

  def test_get_users
    client = Synapse::Client.new(@options)
    response = client.get_users
    assert_instance_of Synapse::Users, response
  end

  def test_get_transaction
    client = Synapse::Client.new(@options)
    response = client.get_all_transaction
    assert_instance_of Synapse::Transactions, response
  end

  def test_get_all_nodes
    client = Synapse::Client.new(@options)
    response = client.get_all_nodes(page: 20, per_page: 50)
    assert_instance_of Synapse::Nodes, response
  end

  # added sleep() methods for all subscription test method to not trigger Synapse::Error::TooManyRequests
  def test_create_subscriptions
    client = Synapse::Client.new(@options)
    body = {
      "scope": [
        'USERS|POST',
        'USER|PATCH',
        'NODES|POST',
        'NODE|PATCH',
        'TRANS|POST',
        'TRAN|PATCH'
      ],
      "url": 'https://requestb.in/zp216zzp'
    }
    response = client.create_subscriptions(scope: body)
    assert_instance_of Synapse::Subscription, response
    sleep(5)
  end

  def test_get_all_subscriptions
    client = Synapse::Client.new(@options)
    response = client.get_all_subscriptions
    assert_instance_of Synapse::Subscriptions, response
    sleep(5)
  end

  def test_get_subscription
    client = Synapse::Client.new(@options)
    subscription = @subscription
    response = client.get_subscription(subscription_id: subscription)
    assert_instance_of Synapse::Subscription, response
    sleep(5)
  end

  def test_get_all_institutions
    client = Synapse::Client.new(@options)
    response = client.get_all_institutions
    assert_instance_of Hash, response
  end

  def test_logging
    client = Synapse::Client.new(@options)
    payload = {
      "logins": [
        {
          "email": 'test@synapsefi.com'
        }
      ],
      "phone_numbers": [
        '901.111.1111',
        'test@synapsefi.com'
      ],
      "legal_names": [
        'Andrew Martin'
      ],
      "extra": {
        "supp_id": '122eddfgbeafrfvbbb',
        "cip_tag": 1,
        "is_business": false
      }
    }
    # fails if the block outputs anything to stderr stdout
    assert_silent { client.create_user(payload: payload, ip_address: '127.0.0.1') }

    @options[:logging] = true
    # failse if stdout does not output the expected results
    assert_output { client.create_user(payload: payload, ip_address: '127.0.0.1') }
  end

  def test_issue_public_key
    client = Synapse::Client.new(@options)
    response = client.issue_public_key(scope: 'CLIENT|CONTROLS')
    assert_equal ['CLIENT|CONTROLS'], response['scope']
    refute_nil response['public_key']
  end
end
