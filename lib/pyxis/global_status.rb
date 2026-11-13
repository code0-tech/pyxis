# frozen_string_literal: true

module Pyxis
  module GlobalStatus
    module_function

    def dry_run?
      Pyxis::Environment.dry_run == 'true'
    end

    def with_faraday_dry_run_bypass
      previous = @faraday_dry_run_bypass
      @faraday_dry_run_bypass = true
      yield
    ensure
      @faraday_dry_run_bypass = previous
    end

    def faraday_dry_run_bypass?
      @faraday_dry_run_bypass
    end
  end
end
