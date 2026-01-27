# frozen_string_literal: true

module Pyxis
  class GitlabClient
    include SemanticLogger::Loggable

    GITLAB_URL = 'https://gitlab.com'

    CLIENT_CONFIGS = {
      release_tools: {
        private_token: ENV.fetch('PYXIS_GL_RELEASE_TOOLS_PRIVATE_TOKEN'),
        user_id: 20643824,
      },
    }.freeze

    def self.client(instance = :release_tools)
      CLIENT_CONFIGS[instance][:client] ||= create_client(instance)
    end

    def self.create_client(instance)
      logger.info('Creating gitlab client', instance: instance)

      client_config = CLIENT_CONFIGS[instance]
      options = {
        url: GITLAB_URL,
        headers: {
          'Private-Token': File.read(client_config[:private_token]),
        },
      }
      faraday = Faraday.new(options)
      faraday.use Pyxis::DryRunEnforcer::FaradayBlocker
      faraday.use Pyxis::Logger::FaradayLogger

      enhance_faraday(faraday)

      faraday
    end

    def self.enhance_faraday(faraday)
      %i[get post put patch delete].each do |method|
        faraday.define_singleton_method(:"#{method}_json") do |*args, **kwargs|
          response = faraday.send(method, *args, **kwargs)
          json = response.body.blank? ? nil : JSON.parse(response.body)

          if json.is_a?(Hash)
            Thor::CoreExt::HashWithIndifferentAccess.new(
              {
                body: Thor::CoreExt::HashWithIndifferentAccess.new(json),
                response: response,
              }
            )
          else
            response
          end
        end
      end
    end
  end
end
