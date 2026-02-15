# frozen_string_literal: true

module Pyxis
  class GithubClient
    include SemanticLogger::Loggable

    CLIENT_CONFIGS = {
      release_tools: {
        app_id: 857194,
        installation_id: 69940866,
        private_key: Pyxis::Environment.github_release_tools_private_key,
      },
      release_tools_approver: {
        app_id: 1373592,
        installation_id: 70116032,
        private_key: Pyxis::Environment.github_release_tools_approver_private_key,
      },
    }.freeze

    class << self
      # @return [Octokit::Client]
      def octokit(instance = :release_tools)
        CLIENT_CONFIGS[instance][:octokit] ||= create_octokit(instance)
      end

      def without_auto_pagination(octokit)
        current_auto_paginate = octokit.instance_variable_get(:@auto_paginate)
        octokit.instance_variable_set(:@auto_paginate, false)
        yield octokit
      ensure
        octokit.instance_variable_set(:@auto_paginate, current_auto_paginate)
      end

      def create_installation_access_token(instance, options = {})
        config = CLIENT_CONFIGS[instance]
        global_client = Octokit::Client.new(bearer_token: create_jwt(config[:private_key], config[:app_id]))
        logger.debug('Created JWT for client', app: global_client.app.slug)
        installation_token = Pyxis::GlobalStatus.with_faraday_dry_run_bypass do
          global_client.create_app_installation_access_token(config[:installation_id], options)
        end

        logger.debug('Created app installation access token',
                     installation_token: installation_token.to_h.except(:token))

        installation_token
      end

      private

      def create_octokit(instance)
        logger.info('Creating octokit client', instance: instance)

        installation_token = create_installation_access_token(instance)
        Octokit::Client.new(bearer_token: installation_token[:token])
      end

      def create_jwt(private_pem, client_id)
        private_key = OpenSSL::PKey::RSA.new(private_pem)

        payload = {
          # issued at time, 60 seconds in the past to allow for clock drift
          iat: Time.now.to_i - 60,
          # JWT expiration time (10 minute maximum, so lets use 8)
          exp: Time.now.to_i + (8 * 60),

          # GitHub App's client ID
          iss: client_id,
        }

        JWT.encode(payload, private_key, 'RS256')
      end
    end
  end
end
