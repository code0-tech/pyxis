# frozen_string_literal: true

module Pyxis
  module GlobalStatus
    module_function

    def dry_run?
      ENV.fetch('DRY_RUN', 'true').downcase == 'true'
    end

    def with_faraday_dry_run_bypass
      @faraday_dry_run_bypass = true
      yield
    ensure
      @faraday_dry_run_bypass = false
    end

    def faraday_dry_run_bypass?
      @faraday_dry_run_bypass
    end
  end
end
