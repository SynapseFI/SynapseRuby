require 'minitest/autorun'
require 'minitest/reporters'
require '../lib/synapse_api/error'
require '../lib/synapse_api/client'
require 'rest-client'
require 'json'

require 'dotenv'
Dotenv.load("../.env")

class ErrorTest < Minitest::Test
  def setup
    @options = {
      client_id:       ENV.fetch('TEST_CLIENT_ID'),
      client_secret:    ENV.fetch('TEST_CLIENT_SECRET'),
      ip_address:       '127.0.0.1',
      fingerprint:      'static_pin',
      development_mode: true
    }
  end

  # request to get a user
  def test_200_response
    client = SynapsePayRest::Client.new(@options)
    user_id = "5bea4453321f48299bac84e8"
    headers = {
        content_type: :json,
        accept: :json,
        'X-SP-GATEWAY' => 'client_id_IvSkbeOZAJlmM4ay81EQC0oD7WnP6X9UtRhKs5Yz|client_secret_1QFnWfLBi02r5yAKhovw8Rq9MNPgCkZE4ulHxdT0',
          'X-SP-USER'    => '|static_pin',
          'X-SP-USER-IP' => '127.0.0.1'
      }
    details = RestClient.get("https://uat-api.synapsefi.com/v3.1/users/#{user_id}", headers)
    #print details.code
    assert_equal 200, details.code
  end

  # sending an api call to the wrong baseurl (production); cleint_id & client_secret doesnt match
  def test_400_response
    client = SynapsePayRest::Client.new(@options)
    user_id = "5bea4453321f48299bac84e8"
    headers = {
        content_type: :json,
        accept: :json,
        'X-SP-GATEWAY' => 'client_id_IvSkbeOZAJlmM4ay81EQC0oD7WnP6X9UtRhKs5Yz|client_secret_1QFnWfLBi02r5yAKhovw8Rq9MNPgCkZE4ulHxdT0',
          'X-SP-USER'    => '|static_pin',
          'X-SP-USER-IP' => '127.0.0.1'
      }

    begin
       RestClient.get("https://api.synapsefi.com/v3.1/users/#{user_id}", headers)
    rescue => e
      details = e.response
      details = JSON.parse(details)
    end

    error = SynapsePayRest::Error.from_response(details)
    assert_instance_of SynapsePayRest::Error::BadRequest, error

    assert_equal "400", details["http_code"]
    assert_equal "200", details["error_code"]
  end

  # getting a users transaction without oauthkey
  def test_401_response
    client = SynapsePayRest::Client.new(@options)
    user = "5bea4453321f48299bac84e8"
    headers = {
        content_type: :json,
        accept: :json,
        'X-SP-GATEWAY' => 'client_id_IvSkbeOZAJlmM4ay81EQC0oD7WnP6X9UtRhKs5Yz|client_secret_1QFnWfLBi02r5yAKhovw8Rq9MNPgCkZE4ulHxdT0',
          'X-SP-USER'    => '|static_pin',
          'X-SP-USER-IP' => '127.0.0.1'
      }

    begin
       RestClient.get("https://api.synapsefi.com/v3.1/users/#{user}/trans", headers)
    rescue => e
      details = e.response
      details = JSON.parse(details)
    end

    error = SynapsePayRest::Error.from_response(details)
    assert_instance_of SynapsePayRest::Error::Unauthorized, error

    assert_equal "401", details["http_code"]
    assert_equal "110", details["error_code"]
  end

  # checks SynapsePayRest::Error to make sure class matches response to the right Error object
  def test_402_response
    response = {
      'error' => {
        'en' => "Request to the API failed"
      },
      'error_code' => '400',
      'http_code' => '402',
      'success' => false
    }

    error = SynapsePayRest::Error.from_response(response)

    assert_instance_of SynapsePayRest::Error::RequestDeclined, error
    assert_kind_of SynapsePayRest::Error::RequestDeclined, error
    assert_equal "Request to the API failed", error.message
    assert_equal '400', error.code
    assert_equal '402', error.http_code
    assert_equal response, error.response
  end

  # updating a a docuemnt that doesnt exist for a user
  def test_404_response
    client = SynapsePayRest::Client.new(@options)
    user_id = "5bea4453321f48299bac84e8"
    user = client.get_user(user_id:user_id)
    user.authenticate
    oauth_key = user.oauth_key

    payload = {
      "documents":[{
        "id":"d02f580c1335a625ab2da2d7e53472d4e7fd664e633387654ebebe15ea696c91",
        "virtual_docs":[{
          "id":"ee596c2896dddc19b76c07a184fe7d3cf5a04b8e94b9108190cac7890739017f",
          "document_value":"111-11-3333",
          "document_type":"SSN"
        }]
      }]
    }
    headers = {
        content_type: :json,
        accept: :json,
        'X-SP-GATEWAY' => 'client_id_IvSkbeOZAJlmM4ay81EQC0oD7WnP6X9UtRhKs5Yz|client_secret_1QFnWfLBi02r5yAKhovw8Rq9MNPgCkZE4ulHxdT0',
          'X-SP-USER'    => "#{oauth_key}|static_pin",
          'X-SP-USER-IP' => '127.0.0.1'
      }
    begin
       RestClient::Request.execute(:method => :patch, :url => "https://uat-api.synapsefi.com/v3.1/users/#{user_id}", :payload => payload.to_json, :headers => headers, :timeout => 300)
    rescue => e
      details = e.response
      details = JSON.parse(details)
    end

    error = SynapsePayRest::Error.from_response(details)
    assert_instance_of SynapsePayRest::Error::NotFound, error

    assert_equal "404", details["http_code"]
    assert_equal "404", details["error_code"]
  end

  # Creating a ACH-US node with a routing number that doesn't exist
  def test_409_response
    client = SynapsePayRest::Client.new(@options)
    user_id = "5bea4453321f48299bac84e8"
    user = client.get_user(user_id:user_id)
    user.authenticate
    oauth_key = user.oauth_key

    headers = {
        content_type: :json,
        accept: :json,
        'X-SP-GATEWAY' => 'client_id_IvSkbeOZAJlmM4ay81EQC0oD7WnP6X9UtRhKs5Yz|client_secret_1QFnWfLBi02r5yAKhovw8Rq9MNPgCkZE4ulHxdT0',
          'X-SP-USER'    => "#{oauth_key}|static_pin",
          'X-SP-USER-IP' => '127.0.0.1'
      }

    payload = {
        "type": "ACH-US",
        "info": {
          "nickname": "Fake Account",
          "account_num": "123221346",
          "routing_num": "051000010",
          "type": "PERSONAL",
          "class": "CHECKING"
        }
      }

    begin
       RestClient::Request.execute(:method => :post, :url => "https://uat-api.synapsefi.com/v3.1/users/#{user_id}/nodes", :payload => payload.to_json, :headers => headers, :timeout => 300)
    rescue => e
      details = e.response
      details = JSON.parse(details)
    end

    error = SynapsePayRest::Error.from_response(details)

    assert_instance_of SynapsePayRest::Error::Conflict, error
    assert_equal "409", details["http_code"]
    assert_equal "400", details["error_code"]
  end

  # checks SynapsePayRest::Error to make sure class matches response to the right Error object
  def test_429_response
    response = {
      'error' => {
        'en' => "Too many requests hit the API too quickly."
      },
      'error_code' => '429',
      'http_code' => '429',
      'success' => false
    }

    error = SynapsePayRest::Error.from_response(response)

    assert_instance_of SynapsePayRest::Error::TooManyRequests, error
    assert_kind_of SynapsePayRest::Error::TooManyRequests, error
    assert_equal "Too many requests hit the API too quickly.", error.message
    assert_equal '429', error.code
    assert_equal response, error.response
  end

  # checks SynapsePayRest::Error to make sure class matches response to the right Error object
  def test_500_response
    response = {
      'error' => {
        'en' => "Too many requests hit the API too quickly."
      },
      'error_code' => '402',
      'http_code' => '500',
      'success' => false
    }

    error = SynapsePayRest::Error.from_response(response)

    assert_instance_of SynapsePayRest::Error::InternalServerError, error
    assert_kind_of SynapsePayRest::Error::InternalServerError, error
    assert_equal "Too many requests hit the API too quickly.", error.message
    assert_equal '402', error.code
    assert_equal response, error.response
  end

  # checks SynapsePayRest::Error to make sure class matches response to the right Error object
  def test_503_response
    response = {
      'error' => {
        'en' => "Service Unavailable. The server is currently unable to handle the request due to a temporary overload or scheduled maintenance."
      },
      'error_code' => '503',
      'http_code' => '503',
      'success' => false
    }

    error = SynapsePayRest::Error.from_response(response)

    assert_instance_of SynapsePayRest::Error::ServiceUnavailable, error
    assert_kind_of SynapsePayRest::Error::ServiceUnavailable, error
    assert_equal "Service Unavailable. The server is currently unable to handle the request due to a temporary overload or scheduled maintenance.", error.message
    assert_equal '503', error.code
    assert_equal response, error.response
  end

end






