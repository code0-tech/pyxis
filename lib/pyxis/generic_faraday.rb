# frozen_string_literal: true

module Pyxis
  class GenericFaraday
    include SemanticLogger::Loggable

    def self.create(options)
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

          Thor::CoreExt::HashWithIndifferentAccess.new(
            {
              body: json.is_a?(Hash) ? Thor::CoreExt::HashWithIndifferentAccess.new(json) : json,
              response: response,
            }
          )
        end
      end
    end
  end
end
