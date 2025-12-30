# frozen_string_literal: true

module Pyxis
  module Logger
    class NoProcessColorFormatter < SemanticLogger::Formatters::Color
      def initialize(**args)
        args[:color_map] ||= ::SemanticLogger::Formatters::Color::ColorMap.new(
          debug: ::SemanticLogger::AnsiColors::CYAN,
          info: ::SemanticLogger::AnsiColors::GREEN,
          warn: ::SemanticLogger::AnsiColors::YELLOW,
          error: ::SemanticLogger::AnsiColors::RED,
          fatal: ::SemanticLogger::AnsiColors::RED
        )

        super
      end

      def process_info
        nil
      end
    end

    class FaradayLogger < Faraday::Middleware
      include ::SemanticLogger::Loggable

      def call(env)
        params = { payload: {} }
        if env.method == :get
          logger.measure_debug("#{env.method.upcase} #{env.url.host}#{env.url.path}", params) do
            result = @app.call(env)
            params[:payload][:response_status] = result.status
            result
          end
        else
          logger.measure_info("#{env.method.upcase} #{env.url.host}#{env.url.path}", params) do
            result = @app.call(env)
            params[:payload][:response_status] = result.status
            result
          end
        end
      end
    end
  end
end

SemanticLogger.application = 'pyxis'
SemanticLogger.default_level = ENV.fetch('LOG_LEVEL', 'debug').to_sym
SemanticLogger.add_appender(io: $stderr, level: SemanticLogger.default_level,
                            formatter: Pyxis::Logger::NoProcessColorFormatter.new)

SemanticLogger.push_tags('dry-run') if Pyxis::GlobalStatus.dry_run?

Octokit::Default::MIDDLEWARE.use Pyxis::Logger::FaradayLogger
