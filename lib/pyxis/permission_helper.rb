# frozen_string_literal: true

module Pyxis
  PermissionError = Class.new(Pyxis::Error)
  module PermissionHelper
    def checks_active?
      ENV['BYPASS_PERMISSION_CHECKS'].nil?
    end

    def assert_executed_by_schedule!
      return unless checks_active?
      return if ENV['CI_PIPELINE_SOURCE'] == 'schedule'

      raise PermissionError, 'This operation can only be run by a pipeline schedule'
    end
  end
end
