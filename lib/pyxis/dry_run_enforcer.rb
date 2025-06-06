# frozen_string_literal: true

module Pyxis
  module DryRunEnforcer
    class FaradayBlocker < Faraday::Middleware
      DryRunError = Class.new(StandardError)
      include ::SemanticLogger::Loggable

      def on_request(env)
        return unless Pyxis::GlobalStatus.dry_run?
        return if env.method == :get

        if Pyxis::GlobalStatus.faraday_dry_run_bypass?
          logger.warn('Request bypassing dry run', method: env.method, url: "#{env.url.host}#{env.url.path}")
          return
        end

        logger.fatal('Blocking request during dry run', method: env.method, url: "#{env.url.host}#{env.url.path}")
        raise DryRunError, 'Request blocked during dry run'
      end
    end
  end
end

Octokit::Default::MIDDLEWARE.use Pyxis::DryRunEnforcer::FaradayBlocker
