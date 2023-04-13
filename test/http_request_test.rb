# frozen_string_literal: true

require 'test_helper'

class HTTPClientTest < Minitest::Test
  def setup
    @options = {
      client_id: ENV.fetch('TEST_CLIENT_ID'),
      client_secret: ENV.fetch('TEST_CLIENT_SECRET'),
      ip_address: '127.0.0.1',
      fingerprint: 'static_pin',
      development_mode: true,
      base_url: 'https://uat-api.synapsefi.com/v3.1'
    }
  end

  def test_base_url
    @http_request = Synapse::HTTPClient.new(base_url: @options[:base_url], client_id: @options[:client_id], client_secret: @options[:client_secret],
                                            fingerprint: @options[:fingerprint], ip_address: @options[:ip_address])

    # @http_request = @client.client

    assert_respond_to @http_request, :base_url
  end

  def test_config_exists_and_returns_a_hash
    @http_request = @client = Synapse::HTTPClient.new(base_url: @options[:base_url], client_id: @options[:client_id], client_secret: @options[:client_secret],
                                                      fingerprint: @options[:fingerprint], ip_address: @options[:ip_address])

    assert_instance_of Hash, @http_request.config
  end

  def test_update_headers
    new_options = {
      fingerprint: 'new fingerprint',
      idemopotency_key: 'new idemopotency_key'
    }

    @client = Synapse::Client.new(@options)

    @http_request = @client.client

    @client.update_headers(fingerprint: new_options[:fingerprint], idemopotency_key: new_options[:idemopotency_key])
    config = @http_request.config

    assert_equal config[:fingerprint], new_options[:fingerprint]
    assert_equal config[:idemopotency_key], new_options[:idemopotency_key]
  end
end
