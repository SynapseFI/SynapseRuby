require 'minitest/autorun'
require 'minitest/reporters'
require '../synapse_api/client'


class ClientTest < Minitest::Test
  def setup
    @options = {
      client_id:       'client_id_IvSkbeOZAJlmM4ay81EQC0oD7WnP6X9UtRhKs5Yz',
      client_secret:    'client_secret_1QFnWfLBi02r5yAKhovw8Rq9MNPgCkZE4ulHxdT0',
      ip_address:       '127.0.0.1',
      fingerprint:      'static_pin',
      development_mode: true
    }
  end

  # Testing HTTP_REQUEST @congfig through client class
  # Testing HTTP_REQUEST @base_url through client class
  def test_configured_through_options
    client = SynapsePayRest::Client.new(@options)
    # these keys don't exist in config
    @options.delete(:development_mode)
    @options[:oauth_key] = ''
    assert_equal client.client.config, @options
    assert_equal client.client.base_url, 'https://uat-api.synapsefi.com/v3.1'
  end

  # Test @base_url when development_mode is false 
  def test_endpoint_changes_when_development_mode_false
    @options[:development_mode] = false
    client = SynapsePayRest::Client.new(@options)
    assert_equal client.client.base_url, 'https://api.synapsefi.com/v3.1'
  end

   # Test if client.client is and instance of HTTPClient
  def test_instance_reader_methods
    client = SynapsePayRest::Client.new(@options)
    # fails if HTTP::CLient is not an instance of the Client class
    assert_instance_of SynapsePayRest::HTTPClient, client.client
  end

  # test whether created user is an instance of SynapsePayRest::User
  def test_create_user
    client = SynapsePayRest::Client.new(@options)
    payload = {
      "logins": [
        {
          "email": "test234@synapsefi.com"
        }
      ],
      "phone_numbers": [
        "921.221.3411",
        "test234@synapsefi.com"
      ],
      "legal_names": [
        "Andrew J"
      ]
    }
    @response = client.create_user(payload: payload)
    assert_instance_of SynapsePayRest::User, @response 
  end

  def test_get_users
    client = SynapsePayRest::Client.new(@options)
    response = client.get_users
    assert_instance_of SynapsePayRest::Users, response 
  end

  def test_get_transaction
    client = SynapsePayRest::Client.new(@options)
    response = client.get_transaction()
    assert_instance_of SynapsePayRest::Transactions, response 
  end

  def test_get_all_nodes
    client = SynapsePayRest::Client.new(@options)
    response = client.get_all_nodes(page: 20, per_page: 50)
    assert_instance_of SynapsePayRest::Nodes, response 
  end
  
  # added sleep() methods for all subscription test method to not trigger SynapsePayRest::Error::TooManyRequests
  def test_create_subscriptions
    client = SynapsePayRest::Client.new(@options)
    response = client.create_subscriptions(scope: ["TRAN|PATCH"], url: "https://webhook.site/155f30bc-0c1a-42b9-b075-12c18fd242c5")
    assert_instance_of SynapsePayRest::Subscription, response 
    sleep(5)
  end

  def test_get_all_subscriptions
    client = SynapsePayRest::Client.new(@options)
    response = client.get_all_subscriptions()
    assert_instance_of SynapsePayRest::Subscriptions, response
    sleep(5)
  end

  def test_get_subscription
    client = SynapsePayRest::Client.new(@options)
    response = client.get_subscription("5beb6f2fbddf603229fe4ec5")
    assert_instance_of SynapsePayRest::Subscription, response
    sleep(5)
  end

  def test_get_all_institutions
    client = SynapsePayRest::Client.new(@options)
    response = client.get_all_institutions()
    assert_instance_of Hash, response
  end

  def test_logging
    client = SynapsePayRest::Client.new(@options)
    payload = {
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
      ],
      "extra": {
        "supp_id": "122eddfgbeafrfvbbb",
        "cip_tag":1,
        "is_business": false
      }
    }
    # fails if the block outputs anything to stderr stdout
    assert_silent { client.create_user(payload: payload) }

    @options[:logging] = true
    # failse if stdout does not output the expected results
    assert_output { client.create_user(payload: payload) }
  end

   def test_issue_public_key
    client = SynapsePayRest::Client.new(@options)
    response = client.issue_public_key(scope: 'CLIENT|CONTROLS')
    assert_equal ['CLIENT|CONTROLS'], response['scope']
    refute_nil response['public_key']
  end

  
end