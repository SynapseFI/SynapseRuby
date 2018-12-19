module Synapse
  # Custom class for handling HTTP and API errors.
  class Error < StandardError
    # Raised on a 4xx HTTP status code
    ClientError = Class.new(self)

    # Raised on the HTTP status code 202
    Accepted = Class.new(ClientError)

    # Raised on the HTTP status code 400
    BadRequest = Class.new(ClientError)

    # Raised on the HTTP status code 401
    Unauthorized = Class.new(ClientError)

    # Raised on the HTTP status code 402
    RequestDeclined = Class.new(ClientError)

    # Raised on the HTTP status code 403
    # Forbidden = Class.new(ClientError)
    # '403' => Synapse::Error::Forbidden,

    # Raised on the HTTP status code 404
    NotFound = Class.new(ClientError)

    # Raised on the HTTP status code 406
    # NotAcceptable = Class.new(ClientError)
    # '406' => Synapse::Error::NotAcceptable,

    # Raised on the HTTP status code 409
    Conflict = Class.new(ClientError)

    # Raised on the HTTP status code 415
    # UnsupportedMediaType = Class.new(ClientError)
    # '415' => Synapse::Error::UnsupportedMediaType,

    # Raised on the HTTP status code 422
    # UnprocessableEntity = Class.new(ClientError)
    # '422' => Synapse::Error::UnprocessableEntity,

    # Raised on the HTTP status code 429
    TooManyRequests = Class.new(ClientError)

    # Raised on a 5xx HTTP status code
    ServerError = Class.new(self)

    # Raised on the HTTP status code 500
    InternalServerError = Class.new(ServerError)

    # Raised on the HTTP status code 502
    # BadGateway = Class.new(ServerError)
    # '502' => Synapse::Error::BadGateway,

    # Raised on the HTTP status code 503
    ServiceUnavailable = Class.new(ServerError)

    # Raised on the HTTP status code 504
    # GatewayTimeout = Class.new(ServerError)
    # '504' => Synapse::Error::GatewayTimeout

    # HTTP status code to Error subclass mapping
    #
    # @todo doesn't do well when there's an html response from nginx for bad gateway/timeout

    ERRORS = {
      '202' => Synapse::Error::Accepted,
      '400' => Synapse::Error::BadRequest,
      '401' => Synapse::Error::Unauthorized,
      '402' => Synapse::Error::RequestDeclined,
      '404' => Synapse::Error::NotFound,
      '409' => Synapse::Error::Conflict,
      '429' => Synapse::Error::TooManyRequests,
      '500' => Synapse::Error::InternalServerError,
      '503' => Synapse::Error::ServiceUnavailable,
    }.freeze

    # The SynapsePay API Error Code
    #
    # @return [Integer]
    attr_reader :code, :http_code

    # The JSON HTTP response in Hash form
    # @return [Hash]
    attr_reader :response, :message

    class << self
      # Create a new error from an HTTP response
      # @param body [String]
      # @param code [Integer]
      # @param http_code [Integer]
      # @return [Synapse::Error]
      def from_response(body)
        message, error_code, http_code = parse_error(body)
        http_code = http_code.to_s
        klass = ERRORS[http_code] || Synapse::Error
        klass.new(message: message, code: error_code, response: body, http_code: http_code)
      end

      private

      def parse_error(body)

        if body.nil? || body.empty?
          ['', nil, nil]

        elsif body['mfa'] && body.is_a?(Hash)
          ["#{body['mfa']["message"] } acces_token: #{body['mfa']["access_token"]}", body['error_code'], body['http_code']]
        elsif body[:mfa] && body.is_a?(Hash)
          ["#{body[:mfa][:message] } acces_token: #{body[:mfa][:access_token]}", body[:error_code], body[:http_code]]

        elsif body['message'] && body.is_a?(Hash)
          [body["message"]["en"], body['error_code'], body['http_code']]
         elsif body[:message] && body.is_a?(Hash)
          [body[:message][:en], body[:error_code], body[:http_code]]

        elsif body.is_a?(Hash) && body['error'].is_a?(Hash)
          [body['error']['en'], body['error_code'], body['http_code']]
        elsif body.is_a?(Hash) && body[:error].is_a?(Hash)
          [body[:error][:en], body[:error_code], body[:http_code]]

        end
      end
    end

    # Initializes a new Error object
    # @param message [Exception, String]
    # @param code [Integer]
    # @param response [Hash]
    # @return [Synapse::Error]
    def initialize(message: '', code: nil, response: {}, http_code:)
      super(message)
      @code     = code
      @response = response
      @message = message
      @http_code = http_code
    end
  end
end
