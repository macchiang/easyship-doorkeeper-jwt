require 'doorkeeper/jwt_assertion/version'
require 'doorkeeper/request/assertion'
require 'doorkeeper/jwt_assertion/railtie'

require 'jwt'

module Doorkeeper
  module JWTAssertion
    attr_reader :jwt, :jwt_header
  end
end

module Doorkeeper
  class Server
    attr_reader :jwt

    def jwt=(jwt)
      @jwt = jwt
      context.instance_variable_set('@jwt', jwt)
    end

    def jwt_header=(jwt_header)
      @jwt_header = jwt_header
      context.instance_variable_set('@jwt_header', jwt_header)
    end
  end
end

module Doorkeeper
  class Config
    option :jwt_key
    option :jwt_use_issuer_as_client_id, default: true
    option :jwt_use_application_public_key_as_key, default: true

    class Builder
      def jwt_secret(key)
        set_jwt(key)
      end

      def jwt_private_key(key_file, passphrase = nil)
        key = OpenSSL::PKey::RSA.new(File.open(key_file), passphrase)
        set_jwt(key)
      end

      def jwt_enable(flag)
        enable_jwt if flag
      end

      private

      def set_jwt(key)
        jwt_key key
      end

      def enable_jwt
        Config.class_eval do
          alias_method :remember_calculate_token_grant_types, :calculate_token_grant_types
          define_method :calculate_token_grant_types do
            remember_calculate_token_grant_types << 'assertion' << 'urn:ietf:params:oauth:grant-type:jwt-bearer'
          end
        end
      end
    end
  end
end

module Doorkeeper
  module Errors
    class ExpiredSignature < DoorkeeperError
    end
  end
end

module Doorkeeper
  module Easyship
    class TokenGenerator
      def self.generate(options = {})
        "#{::Rails.env[0..3]}_" + Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), SecureRandom.hex, options.to_s))
      end
    end
  end
end
